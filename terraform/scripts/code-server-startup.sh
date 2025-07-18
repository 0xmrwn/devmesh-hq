#!/usr/bin/env bash
set -euo pipefail

# DevMesh Code Server startup script
# Uses common functions for standardized setup

# Configuration
TARGET_USER="devmesh"
CODE_SERVER_PORT="443"
TAILSCALE_HOSTNAME="devmesh-code"
TAILSCALE_TAGS="tag:code"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
EXTENSIONS=(
    "ms-python.python"
    "anysphere.pyright"
    "mikestead.dotenv"
    "tamasfe.even-better-toml"
    "eamodio.gitlens"
    "ms-vscode.makefile-tools"
    "charliermarsh.ruff"
    "timonwong.shellcheck"
    "bradlc.vscode-tailwindcss"
    "redhat.vscode-yaml"
    "Google.geminicodeassist"
    "saoudrizwan.claude-dev"
)

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
    unzip \
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

# Allow code-server to bind to privileged port 443 without root
# The capability must be applied to the Node.js binary, not the wrapper script.
if [ -f /usr/lib/code-server/lib/node ]; then
  setcap cap_net_bind_service=+ep /usr/lib/code-server/lib/node
else
  echo "WARNING: code-server node binary not found. Binding to port 443 may fail." >&2
  # Fallback to old method just in case the path changes in a future version.
  setcap cap_net_bind_service=+ep /usr/bin/code-server
fi

# Pre-install extensions as target user (idempotent; code-server skips if already installed)
echo "Pre-installing VSCode extensions..."
sudo -u "$TARGET_USER" -H bash -s -- "${EXTENSIONS[@]}" <<'EOF'
  # Use OpenVSX gallery to avoid MS marketplace ToS issues
  export EXTENSIONS_GALLERY='{"serviceUrl": "https://open-vsx.org/vscode/gallery"}'
  for ext in "$@"; do
    echo "Installing extension: $ext"
    code-server --install-extension "$ext" || echo "Failed to install $ext, continuing..."
  done
EOF

# --- Workspace scaffold + code-server CWD override ---
WORKSPACE_DIR="${TARGET_HOME}/workspace"

# 1.  Create language buckets (idempotent)
mkdir -p "${WORKSPACE_DIR}"/{python,rust,js,data,notebooks,scratch,bin,projects}
chown -R "${TARGET_USER}:${TARGET_USER}" "${WORKSPACE_DIR}"

# 2.  Tell systemd to start code-server in that path.
mkdir -p /etc/systemd/system/code-server@${TARGET_USER}.service.d
cat <<EOF >/etc/systemd/system/code-server@${TARGET_USER}.service.d/override.conf
[Service]
WorkingDirectory=${WORKSPACE_DIR}
ExecStart=
ExecStart=/usr/bin/code-server --config ${TARGET_HOME}/.config/code-server/config.yaml ${WORKSPACE_DIR}
EOF

systemctl daemon-reload   # reload unit files now that the drop-in exists

# --- Development Tools Installation (as target user) ---
# Install uv (Python package manager)
sudo -u "$TARGET_USER" -H bash -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'

# Install nvm and Node.js
sudo -u "$TARGET_USER" -H bash <<'EOF'
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
EOF

# Install Bun
sudo -u "$TARGET_USER" -H bash <<'EOF'
    curl -fsSL https://bun.sh/install | bash

    # Add bun to path for verification
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"

    # Verify installation
    echo "Bun installed successfully."
    echo "Bun version: $(bun -v)"
EOF

# Install Rust
sudo -u "$TARGET_USER" -H bash <<'EOF'
    # Install Rust non-interactively
    curl --proto =https --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

    # Source cargo environment to make rustc and cargo available
    source "$HOME/.cargo/env"

    # Verify installation
    echo "Rust installed successfully."
    echo "Rustc version: $(rustc --version)"
    echo "Cargo version: $(cargo --version)"
EOF

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
USER_CONFIG_DIR="${TARGET_HOME}/.config/code-server"
USER_CERT_DIR="${USER_CONFIG_DIR}/certs"
CERT_FILE="${USER_CERT_DIR}/codeserver.crt"
KEY_FILE="${USER_CERT_DIR}/codeserver.key"
PASSWORD_FILE="${TARGET_HOME}/code-server-password.txt"
CERT_DOMAIN="${TAILSCALE_HOSTNAME}.${TAILNET_NAME}"

# Create necessary directories
mkdir -p "${USER_CERT_DIR}"
chown -R "${TARGET_USER}:${TARGET_USER}" "${TARGET_HOME}/.config"

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
skip-auth-preflight: true
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
log_info "Password file: ${PASSWORD_FILE}"
