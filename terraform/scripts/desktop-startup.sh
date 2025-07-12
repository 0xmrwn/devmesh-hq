#!/usr/bin/env bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

# Minimal GUI + helpers
apt-get update
apt-get -y install --no-install-recommends xfce4 xterm dbus-x11 curl apt-utils

# Chrome Remote Desktop
curl -sSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/google.gpg] \
  http://dl.google.com/linux/chrome-remote-desktop/deb stable main" \
  >/etc/apt/sources.list.d/chrome-remote-desktop.list
apt-get update
apt-get -y install chrome-remote-desktop

# Tailscale
curl -fsSL https://tailscale.com/install.sh | sh
AUTH_KEY=$(gcloud secrets versions access latest \
           --secret=TAILSCALE_AUTHKEY \
           --format='get(payload.data)' | base64 -d)
tailscale up --auth-key="${AUTH_KEY}" \
             --ssh \
             --hostname=devmesh-desktop \
             --advertise-tags=tag:bastion   # <-- FIXED

# Register CRD in headless mode (token valid for 10 min—will re-run if needed)
/opt/google/chrome-remote-desktop/start-host \
    --code="$(curl -s 'https://remotedesktop.google.com/headless' | \
              grep -m1 'host-code' | cut -d\' -f2)" \
    --redirect-url='https://remotedesktop.google.com/' \
    --name='DevMesh-Madrid'