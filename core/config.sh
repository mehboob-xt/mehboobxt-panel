#!/bin/bash

CONFIG_FILE="/etc/mehboobxt/panel.conf"

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

BASE_DIR="/etc/mehboobxt"

SSH_DB="$BASE_DIR/ssh_accounts.db"

SSH_BACKUP_DIR="$BASE_DIR/backup/ssh"

SSH_EXPORT_DIR="$BASE_DIR/export/ssh"
