#!/usr/bin/env bash
set -euo pipefail

# DevMesh Workstation startup script
# Uses common functions for standardized setup

# Configuration
TAILSCALE_HOSTNAME="devmesh-workstation"
TAILSCALE_TAGS="tag:workstation"

# Create standard devmesh user
create_devmesh_user

# Wait for APT locks before package installation
wait_for_apt_lock

# Minimal GUI + helpers
apt-get update
apt-get -y install --no-install-recommends xfce4 xterm dbus-x11 curl apt-utils

# Chrome Remote Desktop
log_info "Installing Chrome Remote Desktop"
mkdir -p /usr/share/keyrings
curl -sSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/google-chrome.gpg] \
  http://dl.google.com/linux/chrome-remote-desktop/deb stable main" \
  >/etc/apt/sources.list.d/chrome-remote-desktop.list
apt-get update
apt-get -y install chrome-remote-desktop

# Setup Tailscale connection
setup_tailscale "$TAILSCALE_HOSTNAME" "$TAILSCALE_TAGS"

# Register CRD in headless mode (token valid for 10 min—will re-run if needed)
log_info "Registering Chrome Remote Desktop"
/opt/google/chrome-remote-desktop/start-host \
    --code="$(curl -s 'https://remotedesktop.google.com/headless' | \
              grep -m1 'host-code' | cut -d\' -f2)" \
    --redirect-url='https://remotedesktop.google.com/' \
    --name='DevMesh-Madrid'

log_info "Workstation setup complete!"