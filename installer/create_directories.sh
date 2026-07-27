#!/bin/bash

set -e

source "$(dirname "$0")/../core/config.sh"
source "$(dirname "$0")/../core/logger.sh"

info "Creating MehboobXT directories..."

DIRS=(
    "$BASE_DIR"
    "$PANEL_DIR"
    "$CONFIG_DIR"
    "$DATA_DIR"
    "$LOG_DIR"
    "$TEMP_DIR"
    "$BACKUP_DIR"
    "$EXPORT_DIR"
    "$API_DIR"
    "$MODULE_DIR"
    "$CORE_DIR"
    "$ASSETS_DIR"
    "$TEMPLATES_DIR"
    "$CACHE_DIR"
    "$SESSION_DIR"

    "$SSH_BACKUP_DIR"
    "$VLESS_BACKUP_DIR"
    "$VMESS_BACKUP_DIR"
    "$TROJAN_BACKUP_DIR"

    "$SSH_EXPORT_DIR"
    "$VLESS_EXPORT_DIR"
    "$VMESS_EXPORT_DIR"
    "$TROJAN_EXPORT_DIR"
)

for dir in "${DIRS[@]}"; do
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        success "Created: $dir"
    else
        warning "Exists: $dir"
    fi
done

chmod 755 "$BASE_DIR"
chmod 755 "$PANEL_DIR"
chmod 700 "$CONFIG_DIR"
chmod 700 "$DATA_DIR"
chmod 755 "$LOG_DIR"
chmod 700 "$BACKUP_DIR"
chmod 755 "$EXPORT_DIR"
chmod 755 "$TEMP_DIR"
chmod 700 "$SESSION_DIR"
chmod 755 "$CACHE_DIR"

success "Directory structure created successfully."

exit 0
