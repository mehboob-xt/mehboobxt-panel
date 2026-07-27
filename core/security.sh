#!/bin/bash

source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/logger.sh"

########################################
# MehboobXT Security Library
# Version: 1.0.0
########################################

is_root() {
    [[ $EUID -eq 0 ]]
}

require_root() {
    if ! is_root; then
        error "Please run as root."
        exit 1
    fi
}

hash_password() {
    local password="$1"

    echo -n "$password" | sha256sum | awk '{print $1}'
}

verify_password() {
    local password="$1"
    local hash="$2"

    [[ "$(hash_password "$password")" == "$hash" ]]
}

generate_token() {
    openssl rand -hex 32
}

generate_api_key() {
    openssl rand -hex 24
}

generate_uuid() {

    if command -v uuidgen >/dev/null 2>&1; then
        uuidgen
    else
        cat /proc/sys/kernel/random/uuid
    fi
}

generate_password() {

    tr -dc 'A-Za-z0-9@#%+=' </dev/urandom | head -c 16

    echo
}

secure_compare() {

    [[ "$1" == "$2" ]]
}

file_secure() {

    local file="$1"

    chmod 600 "$file"
}

directory_secure() {

    local dir="$1"

    chmod 700 "$dir"
}

command_exists() {

    command -v "$1" >/dev/null 2>&1
}

check_dependencies() {

    local deps=(
        openssl
        sha256sum
    )

    for cmd in "${deps[@]}"
    do
        if ! command_exists "$cmd"; then
            error "$cmd is missing."
            return 1
        fi
    done

    success "Security dependencies OK."
}

session_token() {

    generate_token
}

random_string() {

    local length="${1:-32}"

    tr -dc 'A-Za-z0-9' </dev/urandom | head -c "$length"

    echo
}

safe_remove() {

    local target="$1"

    [[ -e "$target" ]] || return

    rm -rf "$target"
}

secure_tempfile() {

    mktemp
}

secure_tempdir() {

    mktemp -d
}

check_dependencies
