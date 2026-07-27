#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================="
echo "      MehboobXT Premium Installer"
echo "========================================="
echo

bash "$SCRIPT_DIR/check_os.sh"
bash "$SCRIPT_DIR/check_network.sh"
bash "$SCRIPT_DIR/system_update.sh"
bash "$SCRIPT_DIR/install_dependencies.sh"

echo
echo "Creating directories..."

mkdir -p /etc/mehboobxt
mkdir -p /var/lib/mehboobxt
mkdir -p /var/log/mehboobxt
mkdir -p /usr/local/mehboobxt

echo "Directories created."

echo
echo "Initializing Core..."

chmod +x "$SCRIPT_DIR"/../core/*.sh

source "$SCRIPT_DIR/../core/config.sh"
source "$SCRIPT_DIR/../core/logger.sh"
source "$SCRIPT_DIR/../core/database.sh"

db_init

success "Database initialized."

echo
success "MehboobXT Premium installed successfully."
echo
echo "Run Panel using:"
echo "bash menu.sh"

exit 0
