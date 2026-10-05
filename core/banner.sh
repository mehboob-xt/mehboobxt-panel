cat << 'EOF' > /opt/mehboobxt/core/banner.sh
#!/usr/bin/env bash
# ==============================================================================
# Mehboob-XT Dynamic Banner & Header
# ==============================================================================

header() {
    clear
    local server_ip
    server_ip=$(get_public_ip)
    local os_info
    os_info=$(grep -oP '(?<=PRETTY_NAME=).+' /etc/os-release 2>/dev/null | tr -d '"' || uname -sr)
    local ram_usage
    ram_usage=$(free -m | awk '/Mem:/ { printf("%d/%d MB (%.1f%%)", $3, $2, $3*100/$2) }')
    local uptime_str
    uptime_str=$(uptime -p | sed 's/up //')

    printf "${CYAN}${BOLD}"
    cat << "BANNER"
  __  __      _     _                 _       __  _______ 
 |  \/  |    | |   | |               | |      \ \/ /_   _|
 | \  / | ___| |__ | |__   ___   ___ | |__     \  /  | |  
 | |\/| |/ _ \ '_ \| '_ \ / _ \ / _ \| '_ \    /  \  | |  
 | |  | |  __/ | | | |_) | (_) | (_) | |_) |  /_/\_\ |_|  
 |_|  |_|\___|_| |_|_.__/ \___/ \___/|_.__/               
BANNER
    printf "${NC}"
    printf "${BLUE}====================================================${NC}\n"
    printf " ${WHITE}OS:${NC} %-25s ${WHITE}IP:${NC} %s\n" "${os_info}" "${server_ip}"
    printf " ${WHITE}RAM:${NC} %-24s ${WHITE}Uptime:${NC} %s\n" "${ram_usage}" "${uptime_str}"
    printf " ${WHITE}Core Engine:${NC} Xray-core / SSH PAM    ${WHITE}Version:${NC} v2.5.0\n"
    printf "${BLUE}====================================================${NC}\n"
}
EOF
chmod +x /opt/mehboobxt/core/banner.sh
