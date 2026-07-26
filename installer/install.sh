#!/bin/bash

# ===================================================
# MehboobXT Premium Installer
# Version : 1.0.0
# Author  : MehboobXT
# ===================================================

set -e
set -u
set -o pipefail

VERSION="1.0.0"

BASE_DIR="/etc/mehboobxt"
PANEL_DIR="/usr/local/mehboobxt"
SERVICE_NAME="mehboobxt"

REPO_URL="https://github.com/mehboob-xt/mehboobxt-panel.git"

INSTALLER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LOG_FILE="/var/log/mehboobxt-install.log"
LOCK_FILE="/tmp/mehboobxt.lock"

FORCE_INSTALL=false
DEBUG=false

export BASE_DIR
export PANEL_DIR
export SERVICE_NAME
export REPO_URL
export LOG_FILE
export INSTALLER_DIR

RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
WHITE="\033[1;37m"
NC="\033[0m"

mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

log() {
    echo "[$(date '+%F %T')] $1" >> "$LOG_FILE"
}


info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    log "[INFO] $1"
}

success() {
    echo -e "${GREEN}[ OK ]${NC} $1"
    log "[ OK ] $1"
}

warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    log "[WARN] $1"
}

error() {
    echo -e "${RED}[FAIL]${NC} $1"
    log "[FAIL] $1"
}

banner() {

clear

echo
echo -e "${CYAN}======================================================${NC}"
echo -e "${WHITE}              MehboobXT Premium Installer${NC}"
echo -e "${GREEN}                    v${VERSION}${NC}"
echo -e "${CYAN}======================================================${NC}"
echo

}


check_root() {

    if [[ $EUID -ne 0 ]]; then
        error "Please run this installer as root."
        exit 1
    fi

    success "Root access verified."

}


step() {

echo
echo -e "${CYAN}================================================${NC}"
echo -e "${WHITE}[STEP]${NC} $1"
echo -e "${CYAN}================================================${NC}"

}


cleanup() {

rm -f "$LOCK_FILE"
rm -rf /tmp/mehboobxt-installer

}

trap cleanup EXIT
trap 'error "Installation failed."; exit 1' ERR


main() {

    banner

    if [[ -f "$LOCK_FILE" ]]; then
    error "Installer is already running."
    exit 1
fi

touch "$LOCK_FILE"

    check_root

    step "Checking Operating System"
    bash "$INSTALLER_DIR/check_os.sh"

    step "Checking Network"
    bash "$INSTALLER_DIR/check_network.sh"

    step "Updating System"
    bash "$INSTALLER_DIR/system_update.sh"

    step "Installing Dependencies"
    bash "$INSTALLER_DIR/install_dependencies.sh"

    step "Creating Directories"
    bash "$INSTALLER_DIR/create_directories.sh"

    step "Creating Databases"
    bash "$INSTALLER_DIR/create_databases.sh"

    step "Creating Configuration"
    bash "$INSTALLER_DIR/create_config.sh"

    step "Downloading Panel"
    bash "$INSTALLER_DIR/download_panel.sh"

    step "Setting Permissions"
    bash "$INSTALLER_DIR/set_permissions.sh"

    step "Creating Service"
    bash "$INSTALLER_DIR/create_service.sh"

    step "Creating Commands"
    bash "$INSTALLER_DIR/create_commands.sh"

    step "Finishing Installation"
    bash "$INSTALLER_DIR/finish_install.sh"

    success "MehboobXT installed successfully."

}

main "$@"
