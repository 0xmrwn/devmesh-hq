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
