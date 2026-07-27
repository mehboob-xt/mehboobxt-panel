#!/bin/bash

set -e

source "$(dirname "$0")/../core/config.sh"
source "$(dirname "$0")/../core/logger.sh"

info "Installing MehboobXT Panel..."

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p "$PANEL_DIR"

cp -r "$SCRIPT_DIR/core" "$PANEL_DIR/"
cp -r "$SCRIPT_DIR/modules" "$PANEL_DIR/" 2>/dev/null || true
cp -r "$SCRIPT_DIR/assets" "$PANEL_DIR/" 2>/dev/null || true
cp -r "$SCRIPT_DIR/templates" "$PANEL_DIR/" 2>/dev/null || true
cp -r "$SCRIPT_DIR/api" "$PANEL_DIR/" 2>/dev/null || true

cp "$SCRIPT_DIR/menu.sh" "$PANEL_DIR/" 2>/dev/null || true

find "$PANEL_DIR" -type f -name "*.sh" -exec chmod +x {} \;

success "Panel files installed successfully."

exit 0
