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
curl -sSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor --batch --yes -o /usr/share/keyrings/google-chrome.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/google-chrome.gpg] \
  http://dl.google.com/linux/chrome-remote-desktop/deb stable main" \
  >/etc/apt/sources.list.d/chrome-remote-desktop.list
apt-get update
apt-get -y install chrome-remote-desktop

# Configure Chrome Remote Desktop session
log_info "Configuring Chrome Remote Desktop session"
echo "exec /etc/X11/Xsession /usr/bin/xfce4-session" > /etc/chrome-remote-desktop-session

# Add devmesh user to chrome-remote-desktop group
log_info "Adding devmesh user to chrome-remote-desktop group"
# Create the group if it doesn't exist
if ! getent group chrome-remote-desktop >/dev/null 2>&1; then
    log_info "Creating chrome-remote-desktop group"
    groupadd chrome-remote-desktop
fi
usermod -a -G chrome-remote-desktop devmesh

# Setup Tailscale connection
setup_tailscale "$TAILSCALE_HOSTNAME" "$TAILSCALE_TAGS"

log_info "Workstation setup complete!"