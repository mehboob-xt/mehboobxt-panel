#!/bin/bash

set -e
set -u
set -o pipefail

info() {
    echo -e "\033[1;34m[INFO]\033[0m $1"
}

success() {
    echo -e "\033[1;32m[ OK ]\033[0m $1"
}

error() {
    echo -e "\033[1;31m[FAIL]\033[0m $1"
}

########################################
# Root Check
########################################

if [[ $EUID -ne 0 ]]; then
    error "Please run as root."
    exit 1
fi

SERVICE_FILE="/etc/systemd/system/mehboobxt.service"

########################################
# Already Exists
########################################

if [[ -f "$SERVICE_FILE" ]]; then
    success "Service already exists."
    exit 0
fi

########################################
# Create Service
########################################

info "Creating systemd service..."

cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=MehboobXT Premium Panel
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/usr/local/mehboobxt
ExecStart=/usr/local/mehboobxt/mehboobxt
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

########################################
# Permissions
########################################

chmod 644 "$SERVICE_FILE"

########################################
# Reload systemd
########################################

systemctl daemon-reload

########################################
# Enable Service
########################################

systemctl enable mehboobxt.service

success "Service enabled."

########################################
# Start Service
########################################

systemctl restart mehboobxt.service || true

success "Service started."

########################################
# Verify
########################################

if systemctl is-enabled mehboobxt.service >/dev/null 2>&1; then
    success "Service verified."
else
    error "Service verification failed."
    exit 1
fi

########################################
# Finish
########################################

success "System service created successfully."

exit 0
