#!/bin/bash

set -e

source "$(dirname "$0")/../core/config.sh"
source "$(dirname "$0")/../core/logger.sh"

info "Creating MehboobXT configuration..."

mkdir -p "$CONFIG_DIR"

cat > "$CONFIG_DIR/panel.conf" <<EOF
# ======================================
# MehboobXT Panel Configuration
# ======================================

PANEL_NAME="MehboobXT"
VERSION="1.0.0"

BASE_DIR="$BASE_DIR"
PANEL_DIR="$PANEL_DIR"
CONFIG_DIR="$CONFIG_DIR"
DATA_DIR="$DATA_DIR"
LOG_DIR="$LOG_DIR"
TEMP_DIR="$TEMP_DIR"
BACKUP_DIR="$BACKUP_DIR"
EXPORT_DIR="$EXPORT_DIR"

SSH_PORT=22
DEBUG=false
AUTO_BACKUP=true
BACKUP_DAYS=7
TIMEZONE="UTC"
EOF

chmod 600 "$CONFIG_DIR/panel.conf"

success "Configuration created successfully."

exit 0
