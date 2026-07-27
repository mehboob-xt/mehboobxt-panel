#!/bin/bash

# ==========================================
# MehboobXT Panel
# Validator Library
# Version: 1.0.0
# ==========================================

validate_username() {
    [[ "$1" =~ ^[a-zA-Z0-9_]{3,32}$ ]]
}

validate_password() {
    [[ ${#1} -ge 6 ]]
}

validate_port() {
    [[ "$1" =~ ^[0-9]+$ ]] || return 1
    (( $1 >= 1 && $1 <= 65535 ))
}

validate_number() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

validate_email() {
    [[ "$1" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]
}

validate_domain() {
    [[ "$1" =~ ^([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$ ]]
}

validate_ipv4() {
    local ip="$1"

    [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1

    IFS='.' read -r o1 o2 o3 o4 <<< "$ip"

    for octet in "$o1" "$o2" "$o3" "$o4"
    do
        (( octet >= 0 && octet <= 255 )) || return 1
    done

    return 0
}

validate_uuid() {
    [[ "$1" =~ ^[0-9a-fA-F-]{36}$ ]]
}

validate_path() {
    [[ -e "$1" ]]
}

validate_file() {
    [[ -f "$1" ]]
}

validate_directory() {
    [[ -d "$1" ]]
}

validate_yes_no() {
    case "$1" in
        y|Y|yes|YES|n|N|no|NO)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

require_value() {
    [[ -n "$1" ]]
}
