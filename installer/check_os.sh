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
# Check OS File
########################################

if [[ ! -f /etc/os-release ]]; then
    error "/etc/os-release not found."
    exit 1
fi

source /etc/os-release

########################################
# Supported Operating Systems
########################################

case "$ID" in

    ubuntu)

        case "$VERSION_ID" in
            20.04|22.04|24.04)
                success "Ubuntu $VERSION_ID detected."
                ;;
            *)
                error "Unsupported Ubuntu version: $VERSION_ID"
                exit 1
                ;;
        esac
        ;;

    debian)

        case "$VERSION_ID" in
            11|12)
                success "Debian $VERSION_ID detected."
                ;;
            *)
                error "Unsupported Debian version: $VERSION_ID"
                exit 1
                ;;
        esac
        ;;

    *)

        error "Unsupported operating system: $ID"

        exit 1

        ;;

esac

########################################
# Architecture
########################################

ARCH=$(uname -m)

case "$ARCH" in

    x86_64)

        success "Architecture : x86_64"

        ;;

    aarch64|arm64)

        success "Architecture : ARM64"

        ;;

    *)

        error "Unsupported architecture : $ARCH"

        exit 1

        ;;

esac

########################################
# Kernel
########################################

KERNEL=$(uname -r)

info "Kernel : $KERNEL"

########################################
# Hostname
########################################

HOST=$(hostname)

info "Hostname : $HOST"

########################################
# Finish
########################################

success "Operating System check completed."
