cat << 'EOF' > /opt/mehboobxt/menu.sh
#!/usr/bin/env bash
# ==============================================================================
# Mehboob-XT Master Interactive CLI Menu
# ==============================================================================

set -u

export PANEL_DIR="/opt/mehboobxt"

# Load Core Dependencies
if [[ -f "${PANEL_DIR}/core/core.sh" ]]; then
    source "${PANEL_DIR}/core/core.sh"
else
    echo "Fatal Error: ${PANEL_DIR}/core/core.sh not found."
    exit 1
fi

# Load protocol & management modules dynamically
load_modules() {
    local modules=(ssh vless vmess trojan referral expiry)
    for mod in "${modules[@]}"; do
        local mod_path="${PANEL_DIR}/modules/${mod}.sh"
        if [[ -f "${mod_path}" ]]; then
            source "${mod_path}"
        fi
    done
}

load_modules

# Main Menu Loop
main_menu() {
    while true; do
        header
        printf " ${GREEN}1.${NC}  SSH Manager\n"
        printf " ${GREEN}2.${NC}  VLESS Manager\n"
        printf " ${GREEN}3.${NC}  VMess Manager\n"
        printf " ${GREEN}4.${NC}  Trojan Manager\n"
        printf " ${GREEN}5.${NC}  Expiry Manager\n"
        printf " ${GREEN}6.${NC}  Referral Manager\n"
        printf " ${GREEN}7.${NC}  System Info\n"
        printf " ${GREEN}8.${NC}  Backup\n"
        printf " ${GREEN}9.${NC}  Update Panel\n"
        printf " ${RED}10.${NC} Exit\n"
        printf "${BLUE}====================================================${NC}\n"
        printf " ${CYAN}Select Option [1-10]:${NC} "
        read -r choice

        case "${choice}" in
            1)
                if declare -f ssh_menu >/dev/null; then ssh_menu; else log_warn "SSH module loading..."; sleep 1; fi
                ;;
            2)
                if declare -f vless_menu >/dev/null; then vless_menu; else log_warn "VLESS module loading..."; sleep 1; fi
                ;;
            3)
                if declare -f vmess_menu >/dev/null; then vmess_menu; else log_warn "VMess module loading..."; sleep 1; fi
                ;;
            4)
                if declare -f trojan_menu >/dev/null; then trojan_menu; else log_warn "Trojan module loading..."; sleep 1; fi
                ;;
            5)
                if declare -f expiry_menu >/dev/null; then expiry_menu; else log_warn "Expiry module loading..."; sleep 1; fi
                ;;
            6)
                if declare -f referral_menu >/dev/null; then referral_menu; else log_warn "Referral module loading..."; sleep 1; fi
                ;;
            7)
                system_info_display
                ;;
            8)
                backup_panel
                ;;
            9)
                update_panel
                ;;
            10)
                clear
                printf "${GREEN}Exiting Mehboob-XT Panel. Goodbye!${NC}\n"
                exit 0
                ;;
            *)
                log_err "Invalid selection. Please choose an option between 1 and 10."
                sleep 1
                ;;
        esac
    done
}

main_menu
EOF
chmod +x /opt/mehboobxt/menu.sh
ln -sf /opt/mehboobxt/menu.sh /usr/local/bin/mehboobxt
