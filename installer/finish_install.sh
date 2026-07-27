#!/bin/bash

set -e

source "$(dirname "$0")/../core/config.sh"
source "$(dirname "$0")/../core/logger.sh"

info "Finalizing MehboobXT installation..."

echo
echo "=========================================="
echo "     MehboobXT Installed Successfully"
echo "=========================================="
echo
echo "Panel Directory : $PANEL_DIR"
echo "Config Directory: $CONFIG_DIR"
echo "Data Directory  : $DATA_DIR"
echo "Logs Directory  : $LOG_DIR"
echo
echo "Run panel using:"
echo
echo "    mehboobxt"
echo
echo "or"
echo
echo "    bash $PANEL_DIR/menu.sh"
echo

success "Installation completed successfully."

exit 0
