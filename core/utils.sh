cat << 'EOF' > /opt/mehboobxt/core/utils.sh
#!/usr/bin/env bash
# ==============================================================================
# Mehboob-XT Core Utilities
# ==============================================================================

# Terminal Colors
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export BLUE='\033[0;34m'
export PURPLE='\033[0;35m'
export CYAN='\033[0;36m'
export WHITE='\033[1;37m'
export NC='\033[0m'
export BOLD='\033[1m'

# Status Loggers
log_info()    { printf "${CYAN}[INFO]${NC} %s\n" "$1"; }
log_success() { printf "${GREEN}[OK]${NC} %s\n" "$1"; }
log_warn()    { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }
log_err()     { printf "${RED}[ERROR]${NC} %s\n" "$1" >&2; }

# Pre-flight Checks
check_root() {
    if [[ "$(id -u)" -ne 0 ]]; then
        log_err "This module must be executed as root."
        exit 1
    fi
}

# Fetch Server Public IPv4
get_public_ip() {
    local ip
    ip=$(curl -4 -s --max-time 3 https://api.ipify.org || \
         curl -4 -s --max-time 3 https://icanhazip.com || \
         curl -4 -s --max-time 3 https://ifconfig.me/ip || \
         hostname -I | awk '{print $1}')
    echo "${ip:-127.0.0.1}"
}

# Check if a TCP Port is currently listening
is_port_in_use() {
    local port="$1"
    ss -tulpn | grep -q ":${port} "
}

# Press Enter to continue helper
press_enter() {
    printf "\n${YELLOW}Press [Enter] to return to the menu...${NC}"
    read -r
}
EOF
chmod +x /opt/mehboobxt/core/utils.sh
