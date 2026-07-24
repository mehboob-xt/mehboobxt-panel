#!/bin/bash

CONFIG_FILE="./config/panel.conf"

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

BASE_DIR="/etc/mehboobxt"

DATA_DIR="$BASE_DIR/data"

BACKUP_DIR="$BASE_DIR/backup"

EXPORT_DIR="$BASE_DIR/export"

LOG_DIR="$BASE_DIR/logs"

TEMP_DIR="$BASE_DIR/tmp"

CONFIG_DIR="$BASE_DIR/config"

API_DIR="$BASE_DIR/api"

SSH_DB="$DATA_DIR/ssh_accounts.db"

VLESS_DB="$DATA_DIR/vless_accounts.db"
