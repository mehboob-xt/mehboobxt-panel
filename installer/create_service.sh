#!/bin/bash

set -e

source "$(dirname "$0")/../core/config.sh"
source "$(dirname "$0")/../core/logger.sh"

info "Creating MehboobXT systemd service..."

cat > /etc/systemd/system/mehboobxt.service <<EOF
[Unit]
Description=MehboobXT Panel
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$PANEL_DIR
ExecStart=/bin/bash $PANEL_DIR/menu.sh
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable mehboobxt.service >/dev/null 2>&1 || true

success "Systemd service created successfully."

exit 0
