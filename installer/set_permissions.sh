#!/bin/bash

set -e

source "$(dirname "$0")/../core/config.sh"
source "$(dirname "$0")/../core/logger.sh"

info "Setting MehboobXT permissions..."

chmod -R 755 "$PANEL_DIR"
chmod -R 700 "$CONFIG_DIR"
chmod -R 700 "$DATA_DIR"
chmod -R 755 "$MODULE_DIR"
chmod -R 755 "$CORE_DIR"
chmod -R 755 "$ASSETS_DIR"
chmod -R 755 "$TEMPLATES_DIR"
chmod -R 700 "$LOG_DIR"
chmod -R 700 "$BACKUP_DIR"
chmod -R 755 "$EXPORT_DIR"
chmod -R 755 "$CACHE_DIR"
chmod -R 700 "$SESSION_DIR"

find "$PANEL_DIR" -type f -name "*.sh" -exec chmod +x {} \;

success "Permissions configured successfully."

exit 0
