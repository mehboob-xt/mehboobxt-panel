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
# Directories
########################################

DIRS=(
    /etc/mehboobxt
    /etc/mehboobxt/config
    /etc/mehboobxt/modules
    /etc/mehboobxt/backups

    /usr/local/mehboobxt
    /usr/local/mehboobxt/bin
    /usr/local/mehboobxt/core
    /usr/local/mehboobxt/modules
    /usr/local/mehboobxt/assets
    /usr/local/mehboobxt/templates
    /usr/local/mehboobxt/logs
    /usr/local/mehboobxt/tmp

    /var/lib/mehboobxt
    /var/lib/mehboobxt/database
    /var/lib/mehboobxt/accounts

    /var/log/mehboobxt
)

########################################
# Create Directories
########################################

for dir in "${DIRS[@]}"; do

    if [[ -d "$dir" ]]; then
        success "$dir already exists."
        continue
    fi

    info "Creating $dir"

    mkdir -p "$dir"

    success "$dir created."

done

########################################
# Permissions
########################################

chmod -R 755 /usr/local/mehboobxt
chmod -R 755 /etc/mehboobxt
chmod -R 755 /var/lib/mehboobxt
chmod -R 755 /var/log/mehboobxt

########################################
# Finish
########################################

success "Directories created successfully."

exit 0
