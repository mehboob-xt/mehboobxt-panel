#!/bin/bash

set -e

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "========================================"
echo "      MehboobXT Installer v1.0.0"
echo "========================================"

bash "$BASE_DIR/check_os.sh"
bash "$BASE_DIR/check_network.sh"
bash "$BASE_DIR/system_updates.sh"
bash "$BASE_DIR/install_dependencies.sh"

bash "$BASE_DIR/create_directories.sh"
bash "$BASE_DIR/download_panel.sh"
bash "$BASE_DIR/create_config.sh"
bash "$BASE_DIR/create_databases.sh"

bash "$BASE_DIR/set_permissions.sh"
bash "$BASE_DIR/create_commands.sh"
bash "$BASE_DIR/create_service.sh"

bash "$BASE_DIR/finish_install.sh"

exit 0
