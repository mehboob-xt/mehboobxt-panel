#!/bin/bash

set -e

source "$(dirname "$0")/../core/config.sh"
source "$(dirname "$0")/../core/logger.sh"

info "Checking operating system..."

if [[ ! -f /etc/os-release ]]; then
    error "Unsupported operating system."
    exit 1
fi

source /etc/os-release

case "$ID" in
    ubuntu|debian)
        success "$PRETTY_NAME detected."
        ;;
    *)
        error "Only Ubuntu and Debian are supported."
        exit 1
        ;;
esac

ARCH=$(uname -m)

case "$ARCH" in
    x86_64|amd64|aarch64|arm64)
        success "Architecture: $ARCH"
        ;;
    *)
        error "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

exit 0
