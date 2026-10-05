#!/usr/bin/env bash
# ==============================================================================
# MehboobXT VPS Panel - Master Installer (Phase 1)
# Production-Grade Architecture & Dependency Bootstrap
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

# --- Color Definitions ---
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# --- Global Paths ---
readonly PANEL_DIR="/opt/mehboobxt"
readonly CLI_BIN="/usr/local/bin/mehboobxt"
readonly SYSTEMD_SERVICE="/etc/systemd/system/mehboobxt.service"
readonly DEFAULT_PORT=2053

# --- Logging Functions ---
log_info()    { echo -e "${CYAN}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_fatal()   { echo -e "${RED}[FATAL]${NC} $1" >&2; exit 1; }

# --- Error Trap ---
trap 'log_fatal "Installation failed at line ${LINENO} while executing: ${BASH_COMMAND}"' ERR

# --- Pre-Flight Checks ---
preflight_check() {
    log_info "Running pre-flight checks..."
    
    if [[ "$(id -u)" -ne 0 ]]; then
        log_fatal "This installer must be run as root. Run: sudo bash $0"
    fi

    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "${ID}" in
            ubuntu|debian)
                log_success "Target OS verified: ${NAME} (${VERSION_ID})"
                ;;
            *)
                log_fatal "Unsupported operating system: ${NAME}. Only Ubuntu and Debian are supported."
                ;;
        esac
    else
        log_fatal "/etc/os-release not detected. Cannot verify OS compatibility."
    fi

    # Suppress interactive prompts in Debian/Ubuntu during upgrades
    export DEBIAN_FRONTEND=noninteractive
    export NEEDRESTART_MODE=a
}

# --- Cleanup Legacy Broken Paths ---
cleanup_legacy() {
    log_info "Auditing and clearing legacy path conflicts..."
    # Stop existing legacy service if running
    if systemctl is-active --quiet mehboobxt 2>/dev/null; then
        systemctl stop mehboobxt || true
    fi
    
    # Remove stale symlinks
    rm -f "${CLI_BIN}"
    
    # Remove old broken directories with hyphen if empty or duplicate
    if [[ -d "/opt/mehboob-xt" && ! -d "${PANEL_DIR}" ]]; then
        mv /opt/mehboob-xt "${PANEL_DIR}"
    fi
    log_success "Legacy cleanup complete."
}

# --- System Dependencies ---
install_dependencies() {
    log_info "Updating system packages and installing dependencies..."
    apt-get update -y -qq
    apt-get install -y -qq --no-install-recommends \
        curl \
        wget \
        unzip \
        git \
        jq \
        tar \
        openssl \
        ca-certificates \
        python3 \
        python3-pip \
        python3-venv \
        ufw \
        fail2ban \
        procps \
        iproute2 \
        net-tools
    log_success "System dependencies installed."
}

# --- Create Directory Structure ---
setup_directories() {
    log_info "Building unified directory architecture in ${PANEL_DIR}..."
    mkdir -p "${PANEL_DIR}"/{app/{api,core,db,static,templates},bin,certs,cli,config,database,logs}
    chmod 750 "${PANEL_DIR}"
    chmod 700 "${PANEL_DIR}"/{certs,database,config}
    log_success "Directory structure created."
}

# --- Install Official Xray-Core ---
install_xray() {
    log_info "Detecting hardware architecture for Xray-core..."
    local raw_arch
    raw_arch="$(uname -m)"
    local xray_arch=""

    case "${raw_arch}" in
        x86_64|amd64)
            xray_arch="64"
            ;;
        aarch64|arm64)
            xray_arch="arm64-v8a"
            ;;
        *)
            log_fatal "Unsupported architecture: ${raw_arch}. Xray-core supports x86_64 and aarch64."
            ;;
    esac

    log_info "Detected architecture: ${raw_arch} (Xray asset: Xray-linux-${xray_arch}.zip)"
    
    local tmp_dir
    tmp_dir="$(mktemp -d)"
    local xray_url="https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-${xray_arch}.zip"

    log_info "Downloading official Xray-core from GitHub..."
    if ! curl -sSL --fail --retry 3 "${xray_url}" -o "${tmp_dir}/xray.zip"; then
        log_fatal "Failed to download Xray-core from ${xray_url}"
    fi

    log_info "Extracting Xray binary and geodata files..."
    unzip -q -o "${tmp_dir}/xray.zip" -d "${tmp_dir}"
    install -m 755 "${tmp_dir}/xray" "${PANEL_DIR}/bin/xray"
    install -m 644 "${tmp_dir}/geoip.dat" "${PANEL_DIR}/bin/geoip.dat"
    install -m 644 "${tmp_dir}/geosite.dat" "${PANEL_DIR}/bin/geosite.dat"
    rm -rf "${tmp_dir}"

    local xray_version
    xray_version="$("${PANEL_DIR}/bin/xray" version | head -n 1)"
    log_success "Installed ${xray_version}"
}

# --- Setup Python Virtual Environment ---
setup_python_env() {
    log_info "Setting up isolated Python 3 virtual environment..."
    python3 -m venv "${PANEL_DIR}/venv"
    
    local pip_bin="${PANEL_DIR}/venv/bin/pip"
    "${pip_bin}" install --upgrade pip setuptools wheel -q

    log_info "Writing requirements.txt..."
    cat << 'EOF' > "${PANEL_DIR}/requirements.txt"
fastapi>=0.110.0
uvicorn[standard]>=0.28.0
pydantic>=2.6.0
pydantic-settings>=2.2.0
sqlalchemy>=2.0.0
aiosqlite>=0.20.0
pyjwt>=2.8.0
bcrypt>=4.0.1
python-multipart>=0.0.9
jinja2>=3.1.3
aiofiles>=23.2.1
psutil>=5.9.8
httpx>=0.27.0
EOF

    log_info "Installing Python dependencies (FastAPI, SQLAlchemy, Uvicorn)..."
    "${pip_bin}" install -r "${PANEL_DIR}/requirements.txt" -q
    log_success "Python virtual environment verified."
}

# --- Generate Configuration Files ---
generate_configs() {
    log_info "Generating default panel and proxy configurations..."
    
    # Generate secure random secret for JWT
    local secret_key
    secret_key="$(openssl rand -hex 32)"

    cat << EOF > "${PANEL_DIR}/config/panel_config.json"
{
  "host": "0.0.0.0",
  "port": ${DEFAULT_PORT},
  "secret_key": "${secret_key}",
  "db_path": "${PANEL_DIR}/database/mehboobxt.db",
  "xray_bin": "${PANEL_DIR}/bin/xray",
  "xray_config": "${PANEL_DIR}/config/xray_config.json",
  "log_dir": "${PANEL_DIR}/logs"
}
EOF

    cat << EOF > "${PANEL_DIR}/config/xray_config.json"
{
  "log": {
    "access": "${PANEL_DIR}/logs/xray_access.log",
    "error": "${PANEL_DIR}/logs/xray_error.log",
    "loglevel": "warning"
  },
  "api": {
    "tag": "api",
    "services": ["HandlerService", "StatsService"]
  },
  "inbounds": [],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "tag": "blocked"
    }
  ]
}
EOF

    touch "${PANEL_DIR}/logs/xray_access.log"
    touch "${PANEL_DIR}/logs/xray_error.log"
    touch "${PANEL_DIR}/logs/panel.log"
    log_success "Configurations written successfully."
}

# --- Deploy Bootstrap FastAPI App ---
deploy_bootstrap_app() {
    log_info "Writing Phase 1 FastAPI entrypoint (${PANEL_DIR}/app/main.py)..."

    cat << 'EOF' > "${PANEL_DIR}/app/main.py"
import os
import json
import psutil
from fastapi import FastAPI
from fastapi.responses import JSONResponse

CONFIG_FILE = "/opt/mehboobxt/config/panel_config.json"

with open(CONFIG_FILE, "r") as f:
    config = json.load(f)

app = FastAPI(
    title="MehboobXT Panel",
    description="High-Performance Enterprise VPS Management Panel",
    version="2.0.0"
)

@app.get("/")
async def root():
    return {
        "status": "online",
        "panel": "MehboobXT Web Panel",
        "version": "2.0.0",
        "phase": "Phase 1 Bootstrap Complete",
        "endpoints": {
            "health": "/health",
            "docs": "/docs"
        }
    }

@app.get("/health")
async def health():
    return JSONResponse(
        status_code=200,
        content={
            "status": "healthy",
            "system": {
                "cpu_usage_percent": psutil.cpu_percent(interval=None),
                "ram_usage_percent": psutil.virtual_memory().percent,
                "disk_usage_percent": psutil.disk_usage("/").percent
            },
            "xray_binary_exists": os.path.isfile(config["xray_bin"]),
            "db_path": config["db_path"]
        }
    )
EOF
    log_success "Phase 1 FastAPI bootstrap code initialized."
}

# --- Setup Systemd Service ---
setup_systemd() {
    log_info "Registering systemd service (${SYSTEMD_SERVICE})..."

    cat << EOF > "${SYSTEMD_SERVICE}"
[Unit]
Description=MehboobXT Web Management Panel
After=network.target network-online.target nss-lookup.target

[Service]
Type=simple
User=root
WorkingDirectory=${PANEL_DIR}
Environment="PYTHONPATH=${PANEL_DIR}"
ExecStart=${PANEL_DIR}/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port ${DEFAULT_PORT} --log-level info
Restart=always
RestartSec=5s
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable mehboobxt.service
    systemctl restart mehboobxt.service
    log_success "mehboobxt.service successfully enabled and started."
}

# --- Setup Global CLI Wrapper ---
setup_cli() {
    log_info "Configuring global CLI manager: ${CLI_BIN}..."

    cat << 'EOF' > "${PANEL_DIR}/cli/mehboobxt.sh"
#!/usr/bin/env bash
set -euo pipefail

PANEL_DIR="/opt/mehboobxt"
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

cmd="${1:-menu}"

case "$cmd" in
    start)
        systemctl start mehboobxt
        echo -e "${GREEN}MehboobXT service started.${NC}"
        ;;
    stop)
        systemctl stop mehboobxt
        echo -e "${YELLOW}MehboobXT service stopped.${NC}"
        ;;
    restart)
        systemctl restart mehboobxt
        echo -e "${GREEN}MehboobXT service restarted.${NC}"
        ;;
    status)
        systemctl status mehboobxt --no-pager
        ;;
    logs)
        journalctl -u mehboobxt -f -n 50
        ;;
    info)
        IP=$(curl -s4 ifconfig.me || hostname -I | awk '{print $1}')
        header
        echo -e "Web Panel URL  : ${GREEN}http://${IP}:${PORT}${NC}"
        echo -e "API Swagger Doc: ${GREEN}http://${IP}:${PORT}/docs${NC}"
        echo -e "Install Path   : ${CYAN}${PANEL_DIR}${NC}"
        echo -e "Service Status : $(systemctl is-active mehboobxt)"
        echo -e "${CYAN}====================================================${NC}"
        ;;
    menu|*)
        header
        IP=$(curl -s4 ifconfig.me || hostname -I | awk '{print $1}')
        echo -e "Panel Status : $(systemctl is-active mehboobxt)"
        echo -e "Web URL      : http://${IP}:${PORT}"
        echo ""
        echo "1) Start Panel"
        echo "2) Stop Panel"
        echo "3) Restart Panel"
        echo "4) View Service Status"
        echo "5) View Live Service Logs"
        echo "6) System Info & Health"
        echo "0) Exit"
        echo ""
        read -rp "Select option [0-6]: " opt
        case "$opt" in
            1) systemctl start mehboobxt && echo -e "${GREEN}Started.${NC}" ;;
            2) systemctl stop mehboobxt && echo -e "${YELLOW}Stopped.${NC}" ;;
            3) systemctl restart mehboobxt && echo -e "${GREEN}Restarted.${NC}" ;;
            4) systemctl status mehboobxt --no-pager ;;
            5) journalctl -u mehboobxt -f -n 50 ;;
            6) "${PANEL_DIR}/cli/mehboobxt.sh" info ;;
            0) exit 0 ;;
            *) echo -e "${RED}Invalid option.${NC}" ;;
        esac
        ;;
esac
EOF

    chmod +x "${PANEL_DIR}/cli/mehboobxt.sh"
    ln -sf "${PANEL_DIR}/cli/mehboobxt.sh" "${CLI_BIN}"
    chmod +x "${CLI_BIN}"
    log_success "CLI link registered at ${CLI_BIN}."
}

# --- Main Pipeline ---
main() {
    echo -e "${BLUE}====================================================${NC}"
    echo -e "${GREEN}   MehboobXT Web Panel - Phase 1 Installation      ${NC}"
    echo -e "${BLUE}====================================================${NC}"

    preflight_check
    cleanup_legacy
    install_dependencies
    setup_directories
    install_xray
    setup_python_env
    generate_configs
    deploy_bootstrap_app
    setup_systemd
    setup_cli

    local public_ip
    public_ip="$(curl -s4 ifconfig.me || hostname -I | awk '{print $1}')"

    echo ""
    echo -e "${GREEN}====================================================${NC}"
    echo -e "${GREEN}  Phase 1 Foundation Deployed Successfully!         ${NC}"
    echo -e "${GREEN}====================================================${NC}"
    echo -e "Panel Web Address : ${CYAN}http://${public_ip}:${DEFAULT_PORT}${NC}"
    echo -e "API Documentation : ${CYAN}http://${public_ip}:${DEFAULT_PORT}/docs${NC}"
    echo -e "CLI Command       : ${YELLOW}mehboobxt${NC}"
    echo -e "Root Directory    : ${CYAN}${PANEL_DIR}${NC}"
    echo -e "${GREEN}====================================================${NC}"
}

main "$@"
