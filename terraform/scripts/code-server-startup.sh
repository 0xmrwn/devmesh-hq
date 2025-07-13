#!/usr/bin/env bash
set -euo pipefail

# DevMesh Code Server startup script
# Uses common functions for standardized setup

# Configuration
TARGET_USER="devmesh"
CODE_SERVER_PORT="8443"
TAILSCALE_HOSTNAME="devmesh-code"
TAILSCALE_TAGS="tag:code"

# Create standard devmesh user
create_devmesh_user

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
# Setup Tailscale connection using common function
setup_tailscale "$TAILSCALE_HOSTNAME" "$TAILSCALE_TAGS"

# Wait for Tailscale to be fully up and get its domain
log_info "Waiting for Tailscale to initialize..."
TAILNET_NAME=""
for i in {1..10}; do
    TAILNET_NAME=$(tailscale status --json | jq -r '.MagicDNSSuffix')
    if [ -n "${TAILNET_NAME}" ]; then
        log_info "Tailscale is up. Tailnet: ${TAILNET_NAME}"
        break
    fi
    sleep 2
done

if [ -z "${TAILNET_NAME}" ]; then
    log_error "Could not determine Tailnet name after 20 seconds."
    tailscale status
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
    log_info "Re-using existing code-server password."
else
    log_info "Generating new code-server password."
    CODE_SERVER_PASSWORD=$(openssl rand -base64 32)
    echo "Code-server password: ${CODE_SERVER_PASSWORD}" > "$PASSWORD_FILE"
    chown "${TARGET_USER}:${TARGET_USER}" "$PASSWORD_FILE"
    chmod 600 "$PASSWORD_FILE"
fi

# Obtain certificate directly into the user's directory with retries
log_info "Waiting for MagicDNS and obtaining certificate for ${CERT_DOMAIN}..."
for i in {1..5}; do
    if tailscale cert --cert-file "${CERT_FILE}" --key-file "${KEY_FILE}" "${CERT_DOMAIN}"; then
        log_info "Certificate obtained successfully."
        break
    fi
    log_info "Attempt $i/5 failed. Retrying in 5 seconds..."
    sleep 5
done

if [ ! -f "${CERT_FILE}" ]; then
    log_error "Could not obtain Tailscale certificate after multiple retries."
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
log_info "Code-server setup complete!"
log_info "Code-server accessible at: https://${CERT_DOMAIN}:${CODE_SERVER_PORT}"
log_info "Password: ${CODE_SERVER_PASSWORD}"
