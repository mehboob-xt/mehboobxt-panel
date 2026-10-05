#!/usr/bin/env bash
set -euo pipefail

PANEL_DIR="/opt/mehboobxt"
PYTHON_BIN="${PANEL_DIR}/venv/bin/python3"
PORT=$(jq -r '.port' "${PANEL_DIR}/config/panel_config.json" 2>/dev/null || echo "2053")

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

header() {
    clear
    echo -e "${CYAN}====================================================${NC}"
    echo -e "${GREEN}          MehboobXT Panel Management CLI           ${NC}"
    echo -e "${CYAN}====================================================${NC}"
}

reset_admin_password() {
    header
    echo -e "${YELLOW}Reset Admin Account Credentials${NC}"
    echo ""
    read -rp "Enter new username [admin]: " new_user
    new_user="${new_user:-admin}"
    read -rsp "Enter new password: " new_pass
    echo ""
    if [[ -z "${new_pass}" ]]; then
        echo -e "${RED}Error: Password cannot be blank.${NC}"
        return 1
    fi

    "${PYTHON_BIN}" - << EOF
import asyncio
from app.db.database import AsyncSessionLocal
from app.db.models import Admin
from app.core.security import get_password_hash
from sqlalchemy import select

async def update_creds():
    async with AsyncSessionLocal() as session:
        res = await session.execute(select(Admin).filter_by(username="${new_user}"))
        admin = res.scalar_one_or_none()
        if admin:
            admin.password_hash = get_password_hash("${new_pass}")
            print(f"Updated password for user: {admin.username}")
        else:
            admin = Admin(username="${new_user}", password_hash=get_password_hash("${new_pass}"))
            session.add(admin)
            print(f"Created new admin: {admin.username}")
        await session.commit()

asyncio.run(update_creds())
EOF
    echo -e "${GREEN}Credentials updated successfully.${NC}"
}

cmd="${1:-menu}"

case "$cmd" in
    start)
        systemctl start mehboobxt mehboobxt-xray
        echo -e "${GREEN}Services started.${NC}"
        ;;
    stop)
        systemctl stop mehboobxt mehboobxt-xray
        echo -e "${YELLOW}Services stopped.${NC}"
        ;;
    restart)
        systemctl restart mehboobxt mehboobxt-xray
        echo -e "${GREEN}Services restarted.${NC}"
        ;;
    status)
        systemctl status mehboobxt mehboobxt-xray --no-pager
        ;;
    logs)
        journalctl -u mehboobxt -u mehboobxt-xray -f -n 50
        ;;
    xray-test)
        /opt/mehboobxt/bin/xray test -config /opt/mehboobxt/config/xray_config.json
        ;;
    reset-admin)
        reset_admin_password
        ;;
    info)
        IP=$(curl -s4 ifconfig.me || hostname -I | awk '{print $1}')
        header
        echo -e "Web Panel URL  : ${GREEN}http://${IP}:${PORT}${NC}"
        echo -e "API Swagger Doc: ${GREEN}http://${IP}:${PORT}/docs${NC}"
        echo -e "Panel Status   : $(systemctl is-active mehboobxt)"
        echo -e "Xray Status    : $(systemctl is-active mehboobxt-xray)"
        echo -e "${CYAN}====================================================${NC}"
        ;;
    menu|*)
        header
        IP=$(curl -s4 ifconfig.me || hostname -I | awk '{print $1}')
        echo -e "Panel Service : $(systemctl is-active mehboobxt)"
        echo -e "Xray Service  : $(systemctl is-active mehboobxt-xray)"
        echo -e "Web URL       : http://${IP}:${PORT}"
        echo ""
        echo "1) Start All Services"
        echo "2) Stop All Services"
        echo "3) Restart All Services"
        echo "4) View Service Status"
        echo "5) View Live Logs"
        echo "6) Test Xray Configuration"
        echo "7) Reset Admin Credentials"
        echo "8) System Info & Health"
        echo "0) Exit"
        echo ""
        read -rp "Select option [0-8]: " opt
        case "$opt" in
            1) systemctl start mehboobxt mehboobxt-xray && echo -e "${GREEN}Started.${NC}" ;;
            2) systemctl stop mehboobxt mehboobxt-xray && echo -e "${YELLOW}Stopped.${NC}" ;;
            3) systemctl restart mehboobxt mehboobxt-xray && echo -e "${GREEN}Restarted.${NC}" ;;
            4) systemctl status mehboobxt mehboobxt-xray --no-pager ;;
            5) journalctl -u mehboobxt -u mehboobxt-xray -f -n 50 ;;
            6) /opt/mehboobxt/bin/xray test -config /opt/mehboobxt/config/xray_config.json ;;
            7) reset_admin_password ;;
            8) "${PANEL_DIR}/cli/mehboobxt.sh" info ;;
            0) exit 0 ;;
            *) echo -e "${RED}Invalid option.${NC}" ;;
        esac
        ;;
esac
