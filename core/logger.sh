#!/bin/bash

source "$(dirname "$0")/config.sh"

timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

mkdir -p "$LOG_DIR"

LOG_FILE="$LOG_DIR/panel.log"

touch "$LOG_FILE"
chmod 600 "$LOG_FILE"

RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
WHITE="\033[1;37m"
NC="\033[0m"

write_log() {

    local level="$1"
    local message="$2"

    echo "[$(timestamp)] [$level] $message" >> "$LOG_FILE"

}

info() {

    echo -e "${BLUE}[INFO]${NC} $1"

    write_log INFO "$1"

}

success() {

    echo -e "${GREEN}[ OK ]${NC} $1"

    write_log SUCCESS "$1"

}

warning() {

    echo -e "${YELLOW}[WARN]${NC} $1"

    write_log WARNING "$1"

}

error() {

    echo -e "${RED}[FAIL]${NC} $1"

    write_log ERROR "$1"

}

debug() {

    if [[ "$DEBUG" == "true" ]]; then

        echo -e "${CYAN}[DEBUG]${NC} $1"

    fi

    write_log DEBUG "$1"

}

separator() {

    echo "------------------------------------------------"

}

banner() {

echo

echo "=========================================="

echo "        MehboobXT Premium Panel"

echo "=========================================="

echo

}

rotate_logs() {

if [[ -f "$LOG_FILE" ]]; then

size=$(wc -c < "$LOG_FILE")

if (( size > 1048576 )); then

mv "$LOG_FILE" "$LOG_FILE.old"

touch "$LOG_FILE"

fi

fi

}


clear_logs() {

> "$LOG_FILE"

success "Logs cleared."

}

view_logs() {

if command -v less >/dev/null 2>&1; then
    less "$LOG_FILE"
else
    cat "$LOG_FILE"
fi

}

tail_logs() {

tail -f "$LOG_FILE"

}


rotate_logs

write_log INFO "Logger initialized."

export LOG_FILE
