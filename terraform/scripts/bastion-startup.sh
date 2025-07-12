#!/usr/bin/env bash
set -euo pipefail

# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Fetch auth-key (base64-decoded) from Secret Manager
AUTH_KEY=$(gcloud secrets versions access latest \
           --secret=TAILSCALE_AUTHKEY \
           --format='get(payload.data)' | base64 -d)

# Bring the node into the tailnet, enable identity-based SSH
tailscale up --auth-key="${AUTH_KEY}" \
             --ssh \
             --hostname=bastion-hub
