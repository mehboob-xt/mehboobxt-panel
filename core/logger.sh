#!/bin/bash

LOG_FILE="${LOG_FILE:-/tmp/mehboobxt.log}"

log() {
    local level="$1"
    shift
    local msg="$*"

    printf "[%s] [%s] %s\n" \
        "$(date '+%F %T')" \
        "$level" \
        "$msg" >> "$LOG_FILE"
}

info() {
    echo -e "\033[1;34m[INFO]\033[0m $*"
    log INFO "$*"
}

success() {
    echo -e "\033[1;32m[ OK ]\033[0m $*"
    log SUCCESS "$*"
}

warning() {
    echo -e "\033[1;33m[WARN]\033[0m $*"
    log WARNING "$*"
}

error() {
    echo -e "\033[1;31m[FAIL]\033[0m $*"
    log ERROR "$*"
}
