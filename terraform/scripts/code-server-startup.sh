#!/usr/bin/env bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

# Configuration
TARGET_USER="ubuntu"
CODE_SERVER_PORT="8443"
# The hostname for the server in the Tailnet
TAILSCALE_HOSTNAME="devmesh-code"
# The tag to apply to the node in Tailscale
TAILSCALE_TAGS="tag:bastion"

# --- APT Lock Handling ---
# Function to wait for APT locks to be released with timeout protection
wait_for_apt_lock() {
    local max_wait=300  # Maximum wait time in seconds (5 minutes)
    local wait_time=0
    local check_interval=5
    
    echo "Checking for APT locks..."
    
    while [ $wait_time -lt $max_wait ]; do
        local locks_found=false
        
        # Check for various APT-related locks
        if sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1; then
            echo "APT lists lock detected (wait time: ${wait_time}s/${max_wait}s)..."
            locks_found=true
        fi
        
        if sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1; then
            echo "DPKG lock detected (wait time: ${wait_time}s/${max_wait}s)..."
            locks_found=true
        fi
        
        if sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; then
            echo "DPKG frontend lock detected (wait time: ${wait_time}s/${max_wait}s)..."
            locks_found=true
        fi
        
        if sudo fuser /var/cache/apt/archives/lock >/dev/null 2>&1; then
            echo "APT cache lock detected (wait time: ${wait_time}s/${max_wait}s)..."
            locks_found=true
        fi
        
        # If no locks found, we're good to go
        if [ "$locks_found" = false ]; then
            echo "No APT locks detected. Proceeding with package operations."
            return 0
        fi
        
        # Wait before checking again
        sleep $check_interval
        wait_time=$((wait_time + check_interval))
    done
    
    # If we get here, we've timed out
    echo "WARNING: APT locks still present after ${max_wait} seconds. Attempting to continue..."
    echo "Active APT processes:"
    pgrep -af "(apt|dpkg)" || echo "No APT processes found"
    
    # Try to kill any hanging apt processes (last resort)
    echo "Attempting to terminate any stale APT processes..."
    sudo pkill -f "apt-get" || true
    sudo pkill -f "dpkg" || true
    sleep 2
    
    return 0
}

# --- User Setup ---
# Ensure target user exists and add to sudo group
if ! id "$TARGET_USER" &>/dev/null; then
    useradd -m -s /bin/bash "$TARGET_USER"
fi
usermod -aG sudo "$TARGET_USER"
echo "${TARGET_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/90-nopasswd

# --- Installation ---
# Wait for APT locks before proceeding
wait_for_apt_lock

apt-get update
apt-get -y install --no-install-recommends \
    curl \
    apt-transport-https \
    sudo \
    openssl \
    git \
    tree \
    jq \
    nano \
    libncursesw5-dev \
    autotools-dev \
    autoconf \
    automake \
    build-essential

# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Install code-server
export HOME=/root
curl -fsSL https://code-server.dev/install.sh | sh

# --- Development Tools Installation (as target user) ---
# Install uv (Python package manager)
sudo -u "$TARGET_USER" bash -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'

# Install nvm and Node.js
sudo -u "$TARGET_USER" bash -c '
    # Download and install nvm
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    
    # Source nvm and install Node.js
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Install Node.js
    nvm install 23
    nvm use 23
    nvm alias default 23
    
    # Verify installation
    echo "Node.js version: $(node -v)"
    echo "npm version: $(npm -v)"
'

# --- Tailscale Setup ---
# Get auth key from Secret Manager
AUTH_KEY=$(gcloud secrets versions access latest \
           --secret=TAILSCALE_AUTHKEY \
           --format='get(payload.data)' | base64 -d)

if [ -z "$AUTH_KEY" ]; then
    echo "FATAL: Failed to retrieve Tailscale auth key from Secret Manager" >&2
    exit 1
fi

# Connect to Tailscale
if ! tailscale up --auth-key="$AUTH_KEY" --ssh --hostname="${TAILSCALE_HOSTNAME}" --advertise-tags="${TAILSCALE_TAGS}"; then
    echo "FATAL: Failed to connect to Tailscale" >&2
    exit 1
fi

# Wait for Tailscale to be fully up and get its domain
echo "Waiting for Tailscale to initialize..."
TAILNET_NAME=""
for i in {1..10}; do
    TAILNET_NAME=$(tailscale status --json | jq -r '.MagicDNSSuffix')
    if [ -n "${TAILNET_NAME}" ]; then
        echo "Tailscale is up. Tailnet: ${TAILNET_NAME}"
        break
    fi
    sleep 2
done

if [ -z "${TAILNET_NAME}" ]; then
    echo "FATAL: Could not determine Tailnet name after 20 seconds." >&2
    tailscale status
    exit 1
fi

# Verify Tailscale connection
if ! tailscale status | grep -q "${TAILSCALE_HOSTNAME}"; then
    echo "FATAL: Tailscale connection verification failed" >&2
    exit 1
fi

# --- Code-Server Configuration & Certificate Setup ---
USER_CONFIG_DIR="/home/${TARGET_USER}/.config/code-server"
USER_CERT_DIR="${USER_CONFIG_DIR}/certs"
CERT_FILE="${USER_CERT_DIR}/codeserver.crt"
KEY_FILE="${USER_CERT_DIR}/codeserver.key"
PASSWORD_FILE="/home/${TARGET_USER}/code-server-password.txt"
CERT_DOMAIN="${TAILSCALE_HOSTNAME}.${TAILNET_NAME}"

# Create necessary directories
mkdir -p "${USER_CERT_DIR}"
chown -R "${TARGET_USER}:${TARGET_USER}" "/home/${TARGET_USER}/.config"

# Idempotent password generation
if [ -f "$PASSWORD_FILE" ]; then
    CODE_SERVER_PASSWORD=$(awk '{print $NF}' "$PASSWORD_FILE")
    echo "Re-using existing code-server password."
else
    echo "Generating new code-server password."
    CODE_SERVER_PASSWORD=$(openssl rand -base64 32)
    echo "Code-server password: ${CODE_SERVER_PASSWORD}" > "$PASSWORD_FILE"
    chown "${TARGET_USER}:${TARGET_USER}" "$PASSWORD_FILE"
    chmod 600 "$PASSWORD_FILE"
fi

# Obtain certificate directly into the user's directory with retries
echo "Waiting for MagicDNS and obtaining certificate for ${CERT_DOMAIN}..."
for i in {1..5}; do
    if tailscale cert --cert-file "${CERT_FILE}" --key-file "${KEY_FILE}" "${CERT_DOMAIN}"; then
        echo "Certificate obtained successfully."
        break
    fi
    echo "Attempt $i/5 failed. Retrying in 5 seconds..."
    sleep 5
done

if [ ! -f "${CERT_FILE}" ]; then
    echo "FATAL: Could not obtain Tailscale certificate after multiple retries." >&2
    exit 1
fi

# Create configuration
cat << EOF > "${USER_CONFIG_DIR}/config.yaml"
bind-addr: 0.0.0.0:${CODE_SERVER_PORT}
auth: password
password: ${CODE_SERVER_PASSWORD}
cert: ${CERT_FILE}
cert-key: ${KEY_FILE}
EOF

# Set correct ownership
chown -R "${TARGET_USER}:${TARGET_USER}" "${USER_CONFIG_DIR}"

# --- Service Setup ---
# Enable and start code-server service
systemctl enable --now "code-server@${TARGET_USER}"

# --- Firewall Setup ---
# Wait for APT locks before installing ufw
wait_for_apt_lock

apt-get -y install ufw
ufw allow ${CODE_SERVER_PORT}/tcp
ufw --force enable

# --- Final Status ---
echo "Setup complete!"
echo "Code-server accessible at: https://${CERT_DOMAIN}:${CODE_SERVER_PORT}"
echo "Password: ${CODE_SERVER_PASSWORD}"