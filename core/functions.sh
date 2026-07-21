#!/bin/bash

# ==========================================
# MehboobXT Panel Core Functions
# Version: 1.0.0
# ==========================================


# Colors
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
NC="\033[0m"


# Header
panel_header() {
    clear
    echo -e "${GREEN}"
    echo "======================================"
    echo "        🚀 MehboobXT Panel"
    echo "        Version 1.0.0"
    echo "======================================"
    echo -e "${NC}"
}


# Success Message
success() {
    echo -e "${GREEN}✔ $1${NC}"
}


# Error Message
error() {
    echo -e "${RED}✘ $1${NC}"
}


# Warning Message
warning() {
    echo -e "${YELLOW}! $1${NC}"
}


# Check Root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "Please run as root"
        exit 1
    fi
}


# Pause
pause() {
    read -p "Press Enter to continue..."
}
# Check Command Exists
check_command() {

    command -v "$1" >/dev/null 2>&1

}


# Install Package Helper
install_package() {

    if ! check_command "$1"
    then
        apt update -y
        apt install "$1" -y
    fi

}


# Check User Exists
user_exists() {

    id "$1" >/dev/null 2>&1

}
# Load Module Helper
load_module() {

    if [ -f "$1" ]
    then
        source "$1"
    else
        error "Module missing: $1"
    fi

}
