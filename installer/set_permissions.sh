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
# Paths
########################################

PANEL_DIR="/usr/local/mehboobxt"

CONFIG_DIR="/etc/mehboobxt"

DATA_DIR="/var/lib/mehboobxt"

LOG_DIR="/var/log/mehboobxt"

########################################
# Verify
########################################

for dir in \
"$PANEL_DIR" \
"$CONFIG_DIR" \
"$DATA_DIR" \
"$LOG_DIR"
do

    if [[ ! -d "$dir" ]]; then
        error "$dir not found."
        exit 1
    fi

done

########################################
# Ownership
########################################

info "Setting ownership..."

chown -R root:root "$PANEL_DIR"
chown -R root:root "$CONFIG_DIR"
chown -R root:root "$DATA_DIR"
chown -R root:root "$LOG_DIR"

success "Ownership configured."

########################################
# Directory Permissions
########################################

find "$PANEL_DIR" -type d -exec chmod 755 {} \;
find "$CONFIG_DIR" -type d -exec chmod 755 {} \;
find "$DATA_DIR" -type d -exec chmod 755 {} \;
find "$LOG_DIR" -type d -exec chmod 755 {} \;

success "Directory permissions configured."

########################################
# File Permissions
########################################

find "$PANEL_DIR" -type f -exec chmod 644 {} \;
find "$CONFIG_DIR" -type f -exec chmod 600 {} \;
find "$DATA_DIR" -type f -exec chmod 600 {} \;
find "$LOG_DIR" -type f -exec chmod 644 {} \;

success "File permissions configured."

########################################
# Executable Scripts
########################################

find "$PANEL_DIR" -name "*.sh" -exec chmod +x {} \;

success "Shell scripts marked executable."

########################################
# Finish
########################################

success "Permissions configured successfully."

exit 0
