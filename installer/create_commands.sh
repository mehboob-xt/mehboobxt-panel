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

########################################
# Variables
########################################

PANEL_DIR="/usr/local/mehboobxt"

COMMAND_FILE="/usr/local/bin/mehboobxt"

########################################
# Create Command
########################################

info "Creating global command..."

cat > "$COMMAND_FILE" <<EOF
#!/bin/bash
exec $PANEL_DIR/menu.sh "\$@"
EOF

########################################
# Permissions
########################################

chmod +x "$COMMAND_FILE"

########################################
# Verify
########################################

if [[ ! -x "$COMMAND_FILE" ]]; then
    error "Command creation failed."
    exit 1
fi

########################################
# PATH Check
########################################

if command -v mehboobxt >/dev/null 2>&1; then
    success "Global command verified."
else
    error "Command verification failed."
    exit 1
fi

########################################
# Finish
########################################

success "Global command created successfully."

exit 0
