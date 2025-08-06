#!/usr/bin/env bash
# Common helpers for DevMesh startup scripts
# NOTE: wait_for_apt_lock removed – we now rely on apt’s DPkg::Lock::Timeout

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# --- Logging ---------------------------------------------------------------
log_info()  { echo "[INFO]  $(date '+%F %T') - $*"; }
log_error() { echo "[ERROR] $(date '+%F %T') - $*" >&2; }

# --- User Creation ---------------------------------------------------------
create_devmesh_user() {
  local use_zsh="${1:-false}"
  local username="devmesh"

  if ! id "$username" &>/dev/null; then
    log_info "Creating $username"
    useradd -m -s "$(command -v "${use_zsh:+zsh}" || echo /bin/bash)" "$username"
  fi

  usermod -aG sudo "$username"
  echo "$username ALL=(ALL) NOPASSWD: ALL" >/etc/sudoers.d/devmesh
}

# --- Tailscale -------------------------------------------------------------
setup_tailscale() {
  local hostname="$1" tags="$2"
  [[ -z "$hostname" || -z "$tags" ]] && { log_error "setup_tailscale needs hostname & tags"; exit 1; }

  curl -fsSL https://tailscale.com/install.sh -o /tmp/ts.sh && bash /tmp/ts.sh
  AUTH_KEY=$(gcloud secrets versions access latest --secret=TAILSCALE_AUTHKEY --format='get(payload.data)' | base64 -d)

  tailscale up --auth-key="$AUTH_KEY" --ssh --hostname="$hostname" --advertise-tags="$tags"

  # Verify Tailscale connection was established
  if ! tailscale status | grep -q "$hostname"; then
    log_error "Tailscale connection verification failed"
    exit 1
  fi
}

# --- Oh‑My‑Zsh -------------------------------------------------------------
install_oh_my_zsh() {
  local user="$1"
  local user_home
  user_home=$(getent passwd "$user" | cut -d: -f6)

  # Skip if OMZ is already there (makes the whole script re‑boot safe)
  if [ -d "${user_home}/.oh-my-zsh" ]; then
    log_info "OhMyZsh already present for ${user}; skipping install."
    return 0
  fi

  # Fresh install
  if ! sudo -u "$user" curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh \
       -o /tmp/omz.sh; then
    log_error "Failed to download OhMyZsh installer"
    return 1
  fi

  if ! sudo -u "$user" sh /tmp/omz.sh --unattended; then
    log_error "OhMyZsh install failed"
    return 1
  fi

  chsh -s "$(command -v zsh)" "$user"
  sudo -u "$user" sed -i 's/^ZSH_THEME=.*/ZSH_THEME="gnzh"/' "${user_home}/.zshrc"
}

# --- GitHub SSH Key Setup -------------------------------------------------
configure_github_ssh() {
  local secret_name="${1:-GITHUB_SSH_KEY}"
  local user="${2:-devmesh}"
  local user_home

  # get home directory for the target user
  if ! user_home=$(getent passwd "$user" | cut -d: -f6); then
    log_error "User '$user' not found; cannot configure GitHub SSH."
    return 1
  fi

  # attempt to fetch the base64‑encoded private key
  local key_b64
  if ! key_b64=$(gcloud secrets versions access latest --secret="$secret_name" \
                    --format='get(payload.data)' 2>/dev/null); then
    log_info "Secret '$secret_name' not found or inaccessible; skipping GitHub SSH setup."
    return 0
  fi

  log_info "Configuring GitHub SSH key for user '$user' from secret '$secret_name'."

  # prepare .ssh directory
  mkdir -p "$user_home/.ssh"
  chmod 700 "$user_home/.ssh"
  chown "$user:$user" "$user_home/.ssh"

  # decode and write the private key
  echo "$key_b64" | base64 -d > "$user_home/.ssh/id_rsa"
  chmod 600 "$user_home/.ssh/id_rsa"
  chown "$user:$user" "$user_home/.ssh/id_rsa"

  # add GitHub to known_hosts to avoid interactive prompt
  ssh-keyscan github.com >> "$user_home/.ssh/known_hosts"
  chmod 644 "$user_home/.ssh/known_hosts"
  chown "$user:$user" "$user_home/.ssh/known_hosts"

  # create SSH config to use this key for GitHub
  cat > "$user_home/.ssh/config" <<EOF
Host github.com
  HostName github.com
  IdentityFile $user_home/.ssh/id_rsa
  IdentitiesOnly yes
EOF
  chmod 644 "$user_home/.ssh/config"
  chown "$user:$user" "$user_home/.ssh/config"

  log_info "GitHub SSH key configured for '$user'."
}
