#!/bin/bash

set -e
set -u
set -o pipefail

info() {
    echo -e "\033[1;34m[INFO]\033[0m $1"
}

success() {
    echo -e "\033[1;32m[ OK ]\033[0m $1"
}

error() {
    echo -e "\033[1;31m[FAIL]\033[0m $1"
}

########################################
# Root Check
########################################

if [[ $EUID -ne 0 ]]; then
    error "Please run as root."
    exit 1
fi

########################################
# Variables
########################################

REPO_URL="https://github.com/mehboob-xt/mehboobxt-panel.git"

INSTALL_DIR="/usr/local/mehboobxt"

TEMP_DIR="/tmp/mehboobxt-download"

########################################
# Cleanup
########################################

rm -rf "$TEMP_DIR"

########################################
# Clone Repository
########################################

info "Downloading MehboobXT Panel..."

if ! git clone "$REPO_URL" "$TEMP_DIR"; then
    error "Git clone failed."
    exit 1
fi

success "Repository downloaded."

########################################
# Install Files
########################################

mkdir -p "$INSTALL_DIR"

cp -rf "$TEMP_DIR"/* "$INSTALL_DIR"/

success "Panel files copied."

########################################
# Cleanup
########################################

rm -rf "$TEMP_DIR"

success "Temporary files removed."

########################################
# Verify
########################################

if [[ ! -f "$INSTALL_DIR/menu.sh" ]]; then
    error "Panel verification failed."
    exit 1
fi

success "Panel verified."

########################################
# Finish
########################################

success "Panel downloaded successfully."

exit 0
