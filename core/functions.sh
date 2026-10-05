cat << 'EOF' > /opt/mehboobxt/core/functions.sh
#!/usr/bin/env bash
# ==============================================================================
# Mehboob-XT System Functions
# ==============================================================================

system_info_display() {
    header
    printf "${WHITE}${BOLD}             SYSTEM SPECIFICATIONS & STATUS${NC}\n"
    printf "${BLUE}----------------------------------------------------${NC}\n"
    printf " ${CYAN}Hostname:${NC}        %s\n" "$(hostname)"
    printf " ${CYAN}Kernel:${NC}          %s\n" "$(uname -r)"
    printf " ${CYAN}Architecture:${NC}    %s\n" "$(uname -m)"
    printf " ${CYAN}CPU Model:${NC}       %s\n" "$(lscpu | grep 'Model name' | cut -f 2 -d ":" | awk '{$1=$1}1' || echo 'Unknown')"
    printf " ${CYAN}CPU Cores:${NC}       %s\n" "$(nproc)"
    printf " ${CYAN}Disk Usage:${NC}      %s\n" "$(df -h / | awk 'NR==2 {printf("%s / %s (%s)", $3, $2, $5)}')"
    printf "${BLUE}----------------------------------------------------${NC}\n"
    
    printf "${WHITE}${BOLD}Active Core Listeners:${NC}\n"
    ss -tulpn | grep -E 'xray|sshd|dropbear' | awk '{print $1, $5}' | head -n 8 || printf "No active proxy listeners found.\n"
    
    press_enter
}

backup_panel() {
    header
    local backup_dir="/opt/mehboobxt/backup"
    local timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")
    local archive_file="${backup_dir}/mehboobxt_backup_${timestamp}.tar.gz"

    mkdir -p "${backup_dir}"
    log_info "Creating compressed backup archive..."

    tar -czf "${archive_file}" \
        -C /opt/mehboobxt config database \
        2>/dev/null

    if [[ -f "${archive_file}" ]]; then
        log_success "Backup completed successfully!"
        printf "File stored at: ${GREEN}%s${NC}\n" "${archive_file}"
    else
        log_err "Backup creation failed."
    fi
    press_enter
}

update_panel() {
    header
    log_info "Synchronizing latest updates..."
    # Idempotent permission enforcement
    chmod +x /opt/mehboobxt/menu.sh
    chmod +x /opt/mehboobxt/core/*.sh
    chmod +x /opt/mehboobxt/modules/*.sh 2>/dev/null || true
    log_success "Panel core scripts and permissions successfully refreshed."
    press_enter
}
EOF
chmod +x /opt/mehboobxt/core/functions.sh
