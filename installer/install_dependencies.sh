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

warning() {
    echo -e "\033[1;33m[WARN]\033[0m $1"
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
# Required Packages
########################################

PACKAGES=(
    curl
    wget
    git
    unzip
    zip
    tar
    jq
    sqlite3
    nginx
    cron
    sudo
    openssl
    ca-certificates
    lsb-release
    gnupg
)

########################################
# Install Packages
########################################

for pkg in "${PACKAGES[@]}"; do

    if dpkg -s "$pkg" >/dev/null 2>&1; then
        success "$pkg already installed."
        continue
    fi

    info "Installing $pkg..."

    if DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg"; then
        success "$pkg installed."
    else
        error "Failed to install $pkg."
        exit 1
    fi

done

########################################
# Verify Installation
########################################

info "Verifying installed packages..."

for pkg in "${PACKAGES[@]}"; do

    if dpkg -s "$pkg" >/dev/null 2>&1; then
        success "$pkg verified."
    else
        error "$pkg verification failed."
        exit 1
    fi

done

########################################
# Finish
########################################

success "All dependencies installed successfully."

exit 0
