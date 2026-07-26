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

CONFIG_DIR="/etc/mehboobxt"
CONFIG_FILE="$CONFIG_DIR/panel.conf"

mkdir -p "$CONFIG_DIR"

########################################
# Create Config
########################################

if [[ -f "$CONFIG_FILE" ]]; then
    success "Configuration already exists."
    exit 0
fi

info "Creating configuration..."

cat > "$CONFIG_FILE" <<EOF
########################################
# MehboobXT Panel Configuration
########################################

PANEL_NAME="MehboobXT"

PANEL_VERSION="1.0.0"

INSTALL_PATH="/usr/local/mehboobxt"

DATA_PATH="/var/lib/mehboobxt"

LOG_PATH="/var/log/mehboobxt"

DB_PATH="/var/lib/mehboobxt/database/mehboobxt.db"

BACKUP_PATH="/etc/mehboobxt/backups"

HOST="0.0.0.0"

PORT="8080"

SSL="false"

DEBUG="false"
EOF

chmod 600 "$CONFIG_FILE"

success "Configuration created."

exit 0
