#!/bin/bash

source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/logger.sh"

require_root() {
    [[ $EUID -eq 0 ]] || {
        error "Please run as root."
        exit 1
    }
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

require_command() {
    command_exists "$1" || {
        error "Required command not found: $1"
        exit 1
    }
}

pause() {
    read -rp "Press Enter to continue..."
}

confirm() {
    read -rp "$1 [y/N]: " ans
    [[ "$ans" =~ ^[Yy]$ ]]
}

create_dir() {
    mkdir -p "$1"
}

create_file() {
    touch "$1"
}

random_string() {
    tr -dc A-Za-z0-9 </dev/urandom | head -c "${1:-16}"
}

today() {
    date '+%F'
}

timestamp() {
    date '+%F %T'
}

die() {
    error "$1"
    exit 1
}
