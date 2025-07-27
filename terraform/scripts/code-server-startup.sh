#!/usr/bin/env bash
set -eEuo pipefail



# --------- Configuration ---------------------------------------------------
TARGET_USER="devmesh"
CODE_SERVER_PORT="443"
TAILSCALE_HOSTNAME="devmesh-code"
TAILSCALE_TAGS="tag:code"
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

# --------- 0. Disable unattended-upgrades during first boot ----------------
systemctl stop unattended-upgrades.service || true
systemctl mask unattended-upgrades.service || true

# --------- 0‑bis. Remove EOL backports if present --------------------------
if grep -Rq 'bullseye-backports' /etc/apt/sources.list*; then
  log_info "Pruning obsolete bullseye-backports repo"
  sed -i '/bullseye-backports/d' /etc/apt/sources.list /etc/apt/sources.list.d/*.list
fi

# --------- 1. Base system packages (single apt txn) -----------------------
systemctl stop apt-daily.timer apt-daily-upgrade.timer || true
systemctl kill --kill-whom=all apt-daily.service apt-daily-upgrade.service || true

apt-get -o DPkg::Lock::Timeout=600 update && \
apt-get -o DPkg::Lock::Timeout=600 -y upgrade && \
apt-get -o DPkg::Lock::Timeout=600 -y install --no-install-recommends \
    curl \
    apt-transport-https \
    sudo \
    openssl \
    unzip \
    git \
    tree \
    zsh \
    jq \
    nano \
    libncursesw5-dev \
    autotools-dev \
    autoconf \
    automake \
    build-essential
apt-get clean && rm -rf /var/lib/apt/lists/*


# --------- 2. User & shell -------------------------------------------------
create_devmesh_user true
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
install_oh_my_zsh "$TARGET_USER"
export TARGET_HOME

# --------- 3. Networking first: Tailscale ---------------------------------
setup_tailscale "$TAILSCALE_HOSTNAME" "$TAILSCALE_TAGS"

# --------- 4. Dev-toolchains (grouped) ------------------------------------
sudo --preserve-env=TARGET_HOME -u devmesh -H bash <<'DEVTOOLS'

set -euo pipefail
export HOME="$TARGET_HOME"

# Python (uv)
curl -LsSf https://astral.sh/uv/install.sh -o /tmp/uv.sh && bash /tmp/uv.sh

# NodeJS via nvm
if [ ! -d "$HOME/.nvm" ]; then
  curl -Lo /tmp/nvm.tar.gz https://github.com/nvm-sh/nvm/archive/v0.40.3.tar.gz
  tar -C /tmp -xf /tmp/nvm.tar.gz
  mkdir -p "$HOME/.nvm"
  cp -r /tmp/nvm-0.40.3/* "$HOME/.nvm/"
fi
export NVM_DIR="$HOME/.nvm"; . "$NVM_DIR/nvm.sh"
nvm install --lts
nvm alias default 'lts/*'

# Bun
if [ ! -d "$HOME/.bun" ]; then
  curl -fsSL https://bun.sh/install -o /tmp/bun.sh && bash /tmp/bun.sh
fi

# Rust via rustup (idempotent, non-interactive)
if ! command -v rustc >/dev/null 2>&1; then
  bash <<'RUSTUP'
    set -euo pipefail
    # Skip PATH checks (avoids a second interactive prompt)
    export RUSTUP_INIT_SKIP_PATH_CHECK=yes
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
      | sh -s -- -y --profile minimal --component rustfmt,clippy   # -y is the key
    . "$HOME/.cargo/env"
    echo "Rust $(rustc -V) and Cargo $(cargo -V) installed."
RUSTUP
fi

# npm packages
npm install -g @google/gemini-cli @anthropic-ai/claude-code
DEVTOOLS

# --------- 5. code-server --------------------------------------------------
export HOME=/root
curl -fsSL https://code-server.dev/install.sh -o /tmp/cs.sh && bash /tmp/cs.sh

# --- systemd drop-in: working dir + bind to :443 with AmbientCapabilities --
mkdir -p /etc/systemd/system/code-server@${TARGET_USER}.service.d
cat >/etc/systemd/system/code-server@${TARGET_USER}.service.d/override.conf <<EOF
[Service]
WorkingDirectory=${TARGET_HOME}/workspace
ExecStart=
ExecStart=/usr/bin/code-server --config ${TARGET_HOME}/.config/code-server/config.yaml ${TARGET_HOME}/workspace
AmbientCapabilities=CAP_NET_BIND_SERVICE   # :contentReference[oaicite:7]{index=7}
EOF
systemctl daemon-reload

# Pre-install extensions as target user
log_info "Pre-installing VSCode extensions..."
sudo -u "$TARGET_USER" -H bash -s -- "${EXTENSIONS[@]}" <<'EOF'
  # Use OpenVSX gallery to avoid MS marketplace ToS issues
  export EXTENSIONS_GALLERY='{"serviceUrl": "https://open-vsx.org/vscode/gallery"}'
  for ext in "$@"; do
    echo "Installing extension: $ext"
    code-server --install-extension "$ext" || echo "Failed to install $ext, continuing..."
  done
EOF

# Workspace buckets
sudo -u "$TARGET_USER" mkdir -p "${TARGET_HOME}"/workspace/{python,rust,js,data,notebooks,scratch,bin,projects}

# --------- 6. TLS via tailscale cert --------------------------------------

# Tailnet readiness
TAILNET=""
for _ in {1..10}; do
  TAILNET=$(tailscale status --json | jq -r '.MagicDNSSuffix')
  if [ -n "$TAILNET" ]; then
    break
  else
    sleep 2
  fi
done
[ -z "$TAILNET" ] && { log_error "MagicDNS still not ready"; exit 1; }

CERT_DOMAIN="${TAILSCALE_HOSTNAME}.${TAILNET}"
USER_CERT_DIR="${TARGET_HOME}/.config/code-server/certs"
mkdir -p "$USER_CERT_DIR"
tailscale cert --cert-file "${USER_CERT_DIR}/codeserver.crt" \
               --key-file  "${USER_CERT_DIR}/codeserver.key" "$CERT_DOMAIN"


# --------- 7. code-server config ------------------------------------------
PASSFILE="${TARGET_HOME}/code-server-password.txt"
if [ ! -f "$PASSFILE" ]; then
  openssl rand -base64 32 >"$PASSFILE"
fi
chown "${TARGET_USER}:${TARGET_USER}" "$PASSFILE"
chmod 600 "$PASSFILE"

# Read password from file
CODE_SERVER_PASSWORD=$(cat "$PASSFILE")
sudo -u "$TARGET_USER" mkdir -p "${TARGET_HOME}/.config/code-server"
cat >"${TARGET_HOME}/.config/code-server/config.yaml" <<EOF
bind-addr: 0.0.0.0:${CODE_SERVER_PORT}
auth: password
password: ${CODE_SERVER_PASSWORD}
cert: ${USER_CERT_DIR}/codeserver.crt
cert-key: ${USER_CERT_DIR}/codeserver.key
skip-auth-preflight: true
EOF
chown -R "${TARGET_USER}:${TARGET_USER}" "${TARGET_HOME}/.config"

# --------- 8. Enable service & wrap-up ------------------------------------
systemctl enable --now "code-server@${TARGET_USER}"
log_info "code-server ready at https://${CERT_DOMAIN}:${CODE_SERVER_PORT}"
log_info "Password stored in ${PASSFILE}"

# --------- 9. Re‑enable unattended‑upgrades at the very end ---------------
systemctl unmask unattended-upgrades.service
systemctl start unattended-upgrades.service
