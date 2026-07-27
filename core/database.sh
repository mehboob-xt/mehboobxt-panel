#!/bin/bash

source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/logger.sh"

db_exists() {
    [[ -f "$1" ]]
}

db_create() {
    local db="$1"

    if db_exists "$db"; then
        return
    fi

    touch "$db"
    chmod 600 "$db"

    success "Database created: $(basename "$db")"
}

db_init() {

    db_create "$DB_USERS"
    db_create "$DB_ADMINS"

    db_create "$DB_SSH"
    db_create "$DB_VLESS"
    db_create "$DB_VMESS"
    db_create "$DB_TROJAN"

    db_create "$DB_REFERRALS"
    db_create "$DB_BACKUPS"
    db_create "$DB_LOGS"
}

db_backup() {

    local file="$1"

    cp "$file" "$BACKUP_DIR/$(basename "$file").$(date +%F-%H%M%S)"
}

db_count() {

    [[ -f "$1" ]] || {
        echo 0
        return
    }

    wc -l < "$1"
}

db_clear() {

    : > "$1"
}

db_remove() {

    rm -f "$1"
}
