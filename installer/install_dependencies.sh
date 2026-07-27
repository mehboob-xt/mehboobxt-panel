#!/bin/bash

set -e

source "$(dirname "$0")/../core/config.sh"
source "$(dirname "$0")/../core/logger.sh"

info "Installing MehboobXT dependencies..."

export DEBIAN_FRONTEND=noninteractive

PACKAGES=(
    curl
    wget
    git
    unzip
    zip
    tar
    jq
    bc
    cron
    socat
    openssl
    sqlite3
    nginx
    lsof
    sudo
    ufw
    net-tools
    dnsutils
    ca-certificates
)

apt-get install -y "${PACKAGES[@]}"

success "Dependencies installed successfully."

exit 0
