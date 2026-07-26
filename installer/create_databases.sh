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

error() {
    echo -e "\033[1;31m[FAIL]\033[0m $1"
}

########################################
# Root Check
########################################

if [[ $EUID -ne 0 ]]; then
    error "Please run as root."
    exit 1
fi

########################################
# Database Directory
########################################

DB_DIR="/var/lib/mehboobxt/database"
DB_FILE="$DB_DIR/mehboobxt.db"

mkdir -p "$DB_DIR"

########################################
# SQLite Check
########################################

command -v sqlite3 >/dev/null || {
    error "sqlite3 is not installed."
    exit 1
}

########################################
# Create Database
########################################

if [[ ! -f "$DB_FILE" ]]; then

    info "Creating database..."

    sqlite3 "$DB_FILE" <<EOF
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE,
    password TEXT,
    role TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS settings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE,
    value TEXT
);

CREATE TABLE IF NOT EXISTS logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    action TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS backups (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    filename TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
EOF

    success "Database created."

else

    success "Database already exists."

fi

########################################
# Permissions
########################################

chmod 600 "$DB_FILE"

########################################
# Finish
########################################

success "Database initialization completed."

exit 0
