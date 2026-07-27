#!/bin/bash

source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/logger.sh"

generate_password() {
    tr -dc 'A-Za-z0-9@#%+=' </dev/urandom | head -c "${1:-16}"
}

password_hash() {
    openssl passwd -6 "$1"
}

check_password_strength() {

    local pass="$1"

    [[ ${#pass} -ge 8 ]] || return 1
    [[ "$pass" =~ [A-Z] ]] || return 1
    [[ "$pass" =~ [a-z] ]] || return 1
    [[ "$pass" =~ [0-9] ]] || return 1

    return 0
}

secure_file() {

    chmod 600 "$1"
}

secure_directory() {

    chmod 700 "$1"
}

verify_owner() {

    [[ "$(stat -c %U "$1")" == "root" ]]
}

sha256_file() {

    sha256sum "$1" | awk '{print $1}'
}

verify_checksum() {

    local file="$1"
    local hash="$2"

    [[ "$(sha256_file "$file")" == "$hash" ]]
}

random_token() {

    openssl rand -hex 32
}

is_port_open() {

    ss -lnt | awk '{print $4}' | grep -q ":$1$"
}

ensure_port_free() {

    if is_port_open "$1"; then
        error "Port $1 already in use."
        return 1
    fi
}

enable_ufw() {

    command -v ufw >/dev/null || return

    ufw --force enable >/dev/null 2>&1
}

allow_port() {

    command -v ufw >/dev/null || return

    ufw allow "$1" >/dev/null 2>&1
}

deny_port() {

    command -v ufw >/dev/null || return

    ufw delete allow "$1" >/dev/null 2>&1
}

disable_root_login() {

    sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

    systemctl restart ssh 2>/dev/null || systemctl restart sshd
}

enable_root_login() {

    sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config

    systemctl restart ssh 2>/dev/null || systemctl restart sshd
}
