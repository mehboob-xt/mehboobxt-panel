cat << 'EOF' > /opt/mehboobxt/core/core.sh
#!/usr/bin/env bash
# ==============================================================================
# Mehboob-XT Core Loader
# ==============================================================================

# Ensure execution base path
export PANEL_DIR="/opt/mehboobxt"

# Source Core Components
source "${PANEL_DIR}/core/utils.sh"
source "${PANEL_DIR}/core/banner.sh"
source "${PANEL_DIR}/core/functions.sh"
EOF
chmod +x /opt/mehboobxt/core/core.sh
