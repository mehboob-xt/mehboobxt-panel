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
# Variables
########################################

PANEL_DIR="/usr/local/mehboobxt"
CONFIG_DIR="/etc/mehboobxt"
DATA_DIR="/var/lib/mehboobxt"
LOG_DIR="/var/log/mehboobxt"

########################################
# Verify Installation
########################################

info "Verifying installation..."

for dir in \
"$PANEL_DIR" \
"$CONFIG_DIR" \
"$DATA_DIR" \
"$LOG_DIR"
do
    if [[ ! -d "$dir" ]]; then
        error "$dir missing."
        exit 1
    fi
done

########################################
# Verify Command
########################################

if ! command -v mehboobxt >/dev/null 2>&1; then
    error "Global command not found."
    exit 1
fi

########################################
# Verify Service
########################################

if systemctl list-unit-files | grep -q mehboobxt.service; then
    success "Systemd service verified."
else
    warning "Systemd service not found."
fi

########################################
# Installation Summary
########################################

echo
echo "=============================================="
echo "      MehboobXT Premium Installed"
echo "=============================================="
echo
echo "Panel Path   : $PANEL_DIR"
echo "Config Path  : $CONFIG_DIR"
echo "Data Path    : $DATA_DIR"
echo "Logs         : $LOG_DIR"
echo
echo "Command      : mehboobxt"
echo "Version      : 1.0.0"
echo

success "Installation completed successfully."

exit 0
