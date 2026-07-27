#!/bin/bash

set -e

source "$(dirname "$0")/../core/config.sh"
source "$(dirname "$0")/../core/logger.sh"

info "Creating MehboobXT command..."

mkdir -p /usr/local/bin

cat > /usr/local/bin/mehboobxt <<EOF
#!/bin/bash
exec "$PANEL_DIR/menu.sh" "\$@"
EOF

chmod +x /usr/local/bin/mehboobxt

success "Global command created successfully."

exit 0
