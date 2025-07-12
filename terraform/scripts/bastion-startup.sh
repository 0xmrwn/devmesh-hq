#!/usr/bin/env bash
set -euo pipefail

# DevMesh Bastion startup script
# Uses common functions for standardized setup

# Configuration
TAILSCALE_HOSTNAME="devmesh-bastion"
TAILSCALE_TAGS="tag:bastion"

# Create standard devmesh user
create_devmesh_user

# Setup Tailscale connection
setup_tailscale "$TAILSCALE_HOSTNAME" "$TAILSCALE_TAGS"

log_info "Bastion setup complete!"
