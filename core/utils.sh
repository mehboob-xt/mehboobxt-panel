#!/bin/bash

source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/logger.sh"

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

require_command() {
    command_exists "$1" || {
        error "$1 is not installed."
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

random_string() {
    tr -dc A-Za-z0-9 </dev/urandom | head -c "${1:-16}"
}

random_number() {
    shuf -i "${1:-1000}-${2:-9999}" -n1
}

generate_uuid() {
    cat /proc/sys/kernel/random/uuid
}

port_used() {
    ss -lnt | awk '{print $4}' | grep -q ":$1$"
}

find_free_port() {
    for port in $(seq 10000 65000); do
        if ! port_used "$port"; then
            echo "$port"
            return
        fi
    done
}

is_root() {
    [[ $EUID -eq 0 ]]
}

check_root() {
    is_root || {
        error "Run as root."
        exit 1
    }
}

make_dir() {
    mkdir -p "$1"
}

remove_file() {
    [[ -f "$1" ]] && rm -f "$1"
}

remove_dir() {
    [[ -d "$1" ]] && rm -rf "$1"
}

file_exists() {
    [[ -f "$1" ]]
}

dir_exists() {
    [[ -d "$1" ]]
}

current
