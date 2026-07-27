#!/bin/bash

# MehboobXT Global Configuration

export PANEL_NAME="MehboobXT"
export PANEL_VERSION="1.0.0"

export BASE_DIR="/etc/mehboobxt"
export PANEL_DIR="/usr/local/mehboobxt"

export CONFIG_DIR="$BASE_DIR/config"
export DATA_DIR="$BASE_DIR/data"
export LOG_DIR="$BASE_DIR/logs"
export TEMP_DIR="/tmp/mehboobxt"

export BACKUP_DIR="$DATA_DIR/backups"
export EXPORT_DIR="$DATA_DIR/exports"

export MODULE_DIR="$PANEL_DIR/modules"
export CORE_DIR="$PANEL_DIR/core"
export ASSETS_DIR="$PANEL_DIR/assets"
export TEMPLATES_DIR="$PANEL_DIR/templates"
export API_DIR="$PANEL_DIR/api"

export CACHE_DIR="$BASE_DIR/cache"
export SESSION_DIR="$BASE_DIR/sessions"

export SSH_BACKUP_DIR="$BACKUP_DIR/ssh"
export VLESS_BACKUP_DIR="$BACKUP_DIR/vless"
export VMESS_BACKUP_DIR="$BACKUP_DIR/vmess"
export TROJAN_BACKUP_DIR="$BACKUP_DIR/trojan"

export SSH_EXPORT_DIR="$EXPORT_DIR/ssh"
export VLESS_EXPORT_DIR="$EXPORT_DIR/vless"
export VMESS_EXPORT_DIR="$EXPORT_DIR/vmess"
export TROJAN_EXPORT_DIR="$EXPORT_DIR/trojan"

export DB_USERS="$DATA_DIR/users.db"
export DB_ADMINS="$DATA_DIR/admins.db"
export DB_SSH="$DATA_DIR/ssh.db"
export DB_VLESS="$DATA_DIR/vless.db"
export DB_VMESS="$DATA_DIR/vmess.db"
export DB_TROJAN="$DATA_DIR/trojan.db"
export DB_REFERRALS="$DATA_DIR/referrals.db"
export DB_BACKUPS="$DATA_DIR/backups.db"
export DB_LOGS="$DATA_DIR/logs.db"

export LOG_FILE="$LOG_DIR/panel.log"
