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
# Required Commands
########################################

for cmd in curl wget ping getent; do
    command -v "$cmd" >/dev/null || {
        error "$cmd is not installed."
        exit 1
    }
done

########################################
# Internet Connectivity
########################################

info "Checking Internet connectivity..."

if ping -c1 -W3 8.8.8.8 >/dev/null 2>&1; then
    success "Internet connection available."
else
    error "No Internet connection."
    exit 1
fi

########################################
# DNS Resolution
########################################

info "Checking DNS resolution..."

if getent hosts github.com >/dev/null; then
    success "DNS resolution working."
else
    error "DNS resolution failed."
    exit 1
fi

########################################
# GitHub HTTPS Access
########################################

info "Checking GitHub access..."

if curl -Is --connect-timeout 10 https://github.com >/dev/null; then
    success "GitHub reachable."
else
    error "Cannot reach GitHub."
    exit 1
fi

########################################
# Public IPv4
########################################

info "Detecting Public IPv4..."

PUBLIC_IP=$(curl -4 -fs https://api.ipify.org || true)

if [[ -n "$PUBLIC_IP" ]]; then
    success "Public IPv4 : $PUBLIC_IP"
else
    warning "Unable to detect Public IPv4."
fi

########################################
# Time Sync
########################################

info "Checking system time..."

DATE=$(date)

success "System Time : $DATE"

########################################
# Finish
########################################

success "Network check completed."
exit 0
