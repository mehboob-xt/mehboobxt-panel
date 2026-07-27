#!/bin/bash

set -e

source "$(dirname "$0")/../core/config.sh"
source "$(dirname "$0")/../core/logger.sh"

info "Creating MehboobXT database..."

mkdir -p "$DATA_DIR"

DB_FILES=(
    "$DATA_DIR/users.db"
    "$DATA_DIR/admins.db"
    "$DATA_DIR/ssh.db"
    "$DATA_DIR/vless.db"
    "$DATA_DIR/vmess.db"
    "$DATA_DIR/trojan.db"
    "$DATA_DIR/referrals.db"
    "$DATA_DIR/backups.db"
    "$DATA_DIR/logs.db"
)

for db in "${DB_FILES[@]}"; do
    if [[ ! -f "$db" ]]; then
        touch "$db"
        chmod 600 "$db"
        success "Created: $(basename "$db")"
    else
        warning "Exists: $(basename "$db")"
    fi
done

success "Database initialized successfully."

exit 0
