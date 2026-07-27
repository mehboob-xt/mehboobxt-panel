#!/bin/bash

set -e

source "$(dirname "$0")/../core/config.sh"
source "$(dirname "$0")/../core/logger.sh"

info "Checking network connectivity..."

HOSTS=(
    "github.com"
    "google.com"
    "1.1.1.1"
)

for host in "${HOSTS[@]}"; do
    if ping -c1 -W3 "$host" >/dev/null 2>&1; then
        success "Reachable: $host"
        exit 0
    fi
done

error "No internet connection detected."
exit 1
