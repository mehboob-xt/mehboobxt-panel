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

if [[ ! -f /etc/os-release ]]; then
    error "/etc/os-release not found."
    exit 1
fi

source /etc/os-release

case "$ID" in
    ubuntu|debian)
        ;;
    *)
        error "Unsupported operating system."
        exit 1
        ;;
esac

if [[ $EUID -ne 0 ]]; then
    error "Please run as root."
    exit 1
fi

info "Updating package index..."

apt-get update -y

success "Package index updated."

info "Upgrading installed packages..."

DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

success "System packages upgraded."

info "Removing unused packages..."

apt-get autoremove -y

success "Unused packages removed."

info "Cleaning package cache..."

apt-get autoclean -y

success "Package cache cleaned."

success "System update completed."

exit 0
