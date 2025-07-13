#!/usr/bin/env bash

# Common functions for DevMesh startup scripts
# Functions for user creation, Tailscale setup, APT lock handling, and logging

# Set non-interactive mode for APT operations
export DEBIAN_FRONTEND=noninteractive

# --- Logging Functions ---
log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*"
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
}

# --- User Creation ---
create_devmesh_user() {
    local username="devmesh"

    log_info "Creating devmesh user"

    # Create user if doesn't exist
    if ! id "$username" &>/dev/null; then
        useradd -m -s /bin/bash "$username"
    fi

    # Add to sudo group
    usermod -aG sudo "$username"

    # Configure passwordless sudo
    echo "$username ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/devmesh

    log_info "devmesh user created"
}

# --- APT Lock Handling ---
wait_for_apt_lock() {
    local max_wait=300  # Maximum wait time in seconds (5 minutes)
    local wait_time=0
    local check_interval=5

    log_info "Checking for APT locks..."

    while [ $wait_time -lt $max_wait ]; do
        local locks_found=false

        # Check for various APT-related locks
        if sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1; then
            log_info "APT lists lock detected (wait time: ${wait_time}s/${max_wait}s)..."
            locks_found=true
        fi

        if sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1; then
            log_info "DPKG lock detected (wait time: ${wait_time}s/${max_wait}s)..."
            locks_found=true
        fi

        if sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; then
            log_info "DPKG frontend lock detected (wait time: ${wait_time}s/${max_wait}s)..."
            locks_found=true
        fi

        if sudo fuser /var/cache/apt/archives/lock >/dev/null 2>&1; then
            log_info "APT cache lock detected (wait time: ${wait_time}s/${max_wait}s)..."
            locks_found=true
        fi

        # If no locks found, we're good to go
        if [ "$locks_found" = false ]; then
            log_info "No APT locks detected. Proceeding with package operations."
            return 0
        fi

        # Wait before checking again
        sleep $check_interval
        wait_time=$((wait_time + check_interval))
    done

    # If we get here, we've timed out
    log_error "APT locks still present after ${max_wait} seconds. Attempting to continue..."
    log_info "Active APT processes:"
    pgrep -af "(apt|dpkg)" || log_info "No APT processes found"

    # Try to kill any hanging apt processes (last resort)
    log_info "Attempting to terminate any stale APT processes..."
    sudo pkill -f "apt-get" || true
    sudo pkill -f "dpkg" || true
    sleep 2

    return 0
}

# --- Tailscale Setup ---
setup_tailscale() {
    local hostname="$1"
    local tags="$2"

    if [ -z "$hostname" ] || [ -z "$tags" ]; then
        log_error "setup_tailscale requires hostname and tags parameters"
        exit 1
    fi

    log_info "Setting up Tailscale: $hostname with tags: $tags"

    # Install Tailscale
    curl -fsSL https://tailscale.com/install.sh | sh || {
        log_error "Failed to install Tailscale"
        exit 1
    }

    # Get auth key from Secret Manager
    AUTH_KEY=$(gcloud secrets versions access latest \
               --secret=TAILSCALE_AUTHKEY \
               --format='get(payload.data)' | base64 -d) || {
        log_error "Failed to retrieve Tailscale auth key from Secret Manager"
        exit 1
    }

    if [ -z "$AUTH_KEY" ]; then
        log_error "Retrieved empty Tailscale auth key"
        exit 1
    fi

    # Connect to Tailscale
    if ! tailscale up \
        --auth-key="$AUTH_KEY" \
        --ssh \
        --hostname="$hostname" \
        --advertise-tags="$tags"; then
        log_error "Failed to connect to Tailscale"
        exit 1
    fi

    # Verify connection
    if ! tailscale status | grep -q "$hostname"; then
        log_error "Tailscale connection verification failed"
        exit 1
    fi

    log_info "Tailscale setup complete for $hostname"
}
