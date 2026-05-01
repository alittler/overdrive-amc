#!/bin/bash

set -euo pipefail

# Colors for feedback
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Detect if running as root (via sudo or direct)
if [ "$EUID" -eq 0 ]; then
    INSTALL_DIR="/opt/overdrive-amc"
    USER_HOME="/root"
else
    INSTALL_DIR="$HOME/.overdrive-amc"
    USER_HOME="$HOME"
fi

# Helper functions for error handling
log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_info "Starting Overdrive-AMC installation..."
log_info "Installation directory: $INSTALL_DIR"

# Check for dependencies
if ! command -v git &> /dev/null; then
    log_info "git is not installed. Installing..."
    apt-get update && apt-get install -y git || {
        log_error "Failed to install git"
        exit 1
    }
fi

# Create installation directory
mkdir -p "$INSTALL_DIR" || {
    log_error "Failed to create directory: $INSTALL_DIR"
    exit 1
}

# Clone or update the repository
if [ -d "$INSTALL_DIR/.git" ]; then
    log_info "Updating existing installation..."
    cd "$INSTALL_DIR" || exit 1
    if ! git pull; then
        log_error "Failed to update repository"
        exit 1
    fi
else
    log_info "Cloning repository..."
    if ! git clone https://github.com/alittler/overdrive-amc.git "$INSTALL_DIR"; then
        log_error "Failed to clone repository"
        exit 1
    fi
fi

# Setup: make scripts executable
cd "$INSTALL_DIR" || exit 1
if [ -f "overdrive.sh" ]; then
    chmod +x overdrive.sh
    log_info "Made overdrive.sh executable"
fi

if [ -f "install.sh" ]; then
    chmod +x install.sh
    log_info "Made install.sh executable"
fi

# Create symlink for system-wide access (if running as root)
if [ "$EUID" -eq 0 ]; then
    ln -sf "$INSTALL_DIR/overdrive.sh" /usr/local/bin/overdrive-amc
    log_info "Symlink created: /usr/local/bin/overdrive-amc"
fi

log_info "Installation complete!"
log_info "To use overdrive-amc, run: $INSTALL_DIR/overdrive.sh"
