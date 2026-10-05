#!/usr/bin/env bash
# ==============================================================================
# MehboobXT VPS Panel - Phase 3 Standalone Deployment Script
# Core Xray-core Engine Integration & Native Linux SSH Subsystem
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

readonly PANEL_DIR="/opt/mehboobxt"
readonly APP_DIR="${PANEL_DIR}/app"
readonly PYTHON_BIN="${PANEL_DIR}/venv/bin/python3"
readonly XRAY_SERVICE_FILE="/etc/systemd/system/mehboobxt-xray.service"

# Terminal Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

log_info()    { echo -e "${CYAN}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_fatal()   { echo -e "${RED}[FATAL]${NC} $1" >&2; exit 1; }

# Pre-flight check
if [[ "$(id -u)" -ne 0 ]]; then
    log_fatal "Must be run as root."
fi

log_info "Creating Phase 3 directory tree..."
mkdir -p "${APP_DIR}/schemas" "${APP_DIR}/services" "${PANEL_DIR}/certs" "${PANEL_DIR}/logs"

# ------------------------------------------------------------------------------
# 1. Native SSH Tunnel Shell Environment
# ------------------------------------------------------------------------------
log_info "Configuring restricted SSH tunnel shell..."
cat << 'SHELL_EOF' > /usr/local/bin/mehboobxt-tunnel-shell
#!/bin/sh
# MehboobXT Restricted Tunnel Shell - Blocks shell access while keeping tunnel open
trap '' INT TSTP TERM
echo "=================================================="
echo " MehboobXT SSH Tunnel Connection Active"
echo " Interactive terminal execution is prohibited."
echo "=================================================="
while true; do
    sleep 86400
done
SHELL_EOF

chmod 755 /usr/local/bin/mehboobxt-tunnel-shell

if ! grep -q "^/usr/local/bin/mehboobxt-tunnel-shell" /etc/shells; then
    echo "/usr/local/bin/mehboobxt-tunnel-shell" >> /etc/shells
    log_success "Registered /usr/local/bin/mehboobxt-tunnel-shell in /etc/shells"
fi

# Ensure group exists
if ! getent group mehboobxt_tunnel >/dev/null; then
    groupadd mehboobxt_tunnel
    log_success "Created group 'mehboobxt_tunnel'"
fi

# Configure OpenSSH for Tunnel Group
readonly SSHD_DROPIN="/etc/ssh/sshd_config.d/mehboobxt.conf"
mkdir -p /etc/ssh/sshd_config.d
cat << 'SSHD_EOF' > "${SSHD_DROPIN}"
# MehboobXT SSH Tunnel Subsystem
Match Group mehboobxt_tunnel
    AllowTcpForwarding yes
    X11Forwarding no
    AllowAgentForwarding no
    PasswordAuthentication yes
SSHD_EOF

systemctl reload ssh || systemctl reload sshd || true

# ------------------------------------------------------------------------------
# 2. Schemas: Xray & SSH (Pydantic v2)
# ------------------------------------------------------------------------------
log_info "Writing Schemas (${APP_DIR}/schemas/xray.py)..."
cat << 'PYEOF' > "${APP_DIR}/schemas/xray.py"
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any

class RealitySettings(BaseModel):
    dest: str = "www.microsoft.com:443"
    server_names: List[str] = ["www.microsoft.com"]
    private_key: str
    public_key: str
    short_ids: List[str] = [""]
    fingerprint: str = "chrome"
    spider_x: str = "/"

class StreamSettings(BaseModel):
    network: str = "tcp"  # tcp, ws, grpc, xhttp
    security: str = "none"  # none, tls, reality
    reality_settings: Optional[RealitySettings] = None
    ws_path: Optional[str] = "/ws"
    grpc_service_name: Optional[str] = None
    tls_server_name: Optional[str] = None

class InboundCreate(BaseModel):
    tag: str = Field(..., min_length=2, max_length=64)
    protocol: str = Field(..., pattern="^(vless|vmess|trojan)$")
    port: int = Field(..., ge=1, le=65535)
    listen: str = "0.0.0.0"
    stream: StreamSettings = StreamSettings()
    sniffing_enabled: bool = True
    total_limit_bytes: int = 0
    expiry_timestamp: int = 0
    is_enabled: bool = True

class InboundUpdate(BaseModel):
    listen: Optional[str] = None
    stream: Optional[StreamSettings] = None
    sniffing_enabled: Optional[bool] = None
    total_limit_bytes: Optional[int] = None
    expiry_timestamp: Optional[int] = None
    is_enabled: Optional[bool] = None

class InboundResponse(BaseModel):
    id: int
    tag: str
    protocol: str
    port: int
    listen: str
    stream: StreamSettings
    sniffing_enabled: bool
    up_bytes: int
    down_bytes: int
    total_limit_bytes: int
    expiry_timestamp: int
    is_enabled: bool
    client_count: int = 0

class ClientCreate(BaseModel):
    inbound_id: int
    email: str = Field(..., min_length=3, max_length=128)
    uuid: Optional[str] = None
    flow: Optional[str] = ""
    total_limit_bytes: int = 0
    expiry_timestamp: int = 0
    is_enabled: bool = True

class ClientUpdate(BaseModel):
    flow: Optional[str] = None
    total_limit_bytes: Optional[int] = None
    expiry_timestamp: Optional[int] = None
    is_enabled: Optional[bool] = None

class ClientResponse(BaseModel):
    id: int
    inbound_id: Optional[int]
    email: str
    uuid: str
    flow: Optional[str]
    up_bytes: int
    down_bytes: int
    total_limit_bytes: int
    expiry_timestamp: int
    is_enabled: bool
    client_type: str
    share_link: Optional[str] = None
PYEOF

log_info "Writing Schemas (${APP_DIR}/schemas/ssh.py)..."
cat << 'PYEOF' > "${APP_DIR}/schemas/ssh.py"
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional

class SSHTunnelUserCreate(BaseModel):
    username: str = Field(..., min_length=3, max_length=32, pattern=r"^[a-zA-Z0-9_]+$")
    password: str = Field(..., min_length=4, max_length=64)
    expiry_date: Optional[datetime] = None
    max_connections: int = Field(default=2, ge=1, le=50)
    is_active: bool = True

class SSHTunnelUserUpdate(BaseModel):
    password: Optional[str] = Field(None, min_length=4, max_length=64)
    expiry_date: Optional[datetime] = None
    max_connections: Optional[int] = Field(None, ge=1, le=50)
    is_active: Optional[bool] = None

class SSHTunnelUserResponse(BaseModel):
    id: int
    username: str
    expiry_date: Optional[datetime]
    max_connections: int
    is_active: bool
    up_bytes: int
    down_bytes: int
    created_at: datetime
PYEOF

# ------------------------------------------------------------------------------
# 3. Core: Xray Config Generator & Safe Process Engine
# ------------------------------------------------------------------------------
log_info "Writing Xray Config Generator (${APP_DIR}/core/xray_config.py)..."
cat << 'PYEOF' > "${APP_DIR}/core/xray_config.py"
import json
from typing import List, Dict, Any
from app.db.models import Inbound, Client

def build_xray_config(inbounds: List[Inbound], clients_map: Dict[int, List[Client]]) -> Dict[str, Any]:
    """Builds standard, verified Xray-core JSON structure."""
    xray_inbounds = []

    for ib in inbounds:
        if not ib.is_enabled:
            continue

        raw_stream = json.loads(ib.stream_settings_json) if ib.stream_settings_json else {}
        network = raw_stream.get("network", "tcp")
        security = raw_stream.get("security", "none")

        ib_clients = clients_map.get(ib.id, [])
        client_list = []

        if ib.protocol in ("vless", "vmess"):
            for cl in ib_clients:
                if cl.is_enabled:
                    client_entry = {
                        "id": cl.uuid,
                        "email": cl.email
                    }
                    if ib.protocol == "vless" and cl.flow:
                        client_entry["flow"] = cl.flow
                    elif ib.protocol == "vmess":
                        client_entry["alterId"] = 0
                    client_list.append(client_entry)
            
            inbound_settings = {
                "clients": client_list,
                "decryption": "none" if ib.protocol == "vless" else None
            }
            if inbound_settings["decryption"] is None:
                del inbound_settings["decryption"]

        elif ib.protocol == "trojan":
            for cl in ib_clients:
                if cl.is_enabled:
                    client_list.append({
                        "password": cl.uuid,
                        "email": cl.email
                    })
            inbound_settings = {"clients": client_list}
        else:
            inbound_settings = {}

        # Stream Settings
        stream_dict = {"network": network, "security": security}

        if security == "reality":
            rs = raw_stream.get("reality_settings", {})
            stream_dict["realitySettings"] = {
                "show": False,
                "dest": rs.get("dest", "www.microsoft.com:443"),
                "xver": 0,
                "serverNames": rs.get("server_names", ["www.microsoft.com"]),
                "privateKey": rs.get("private_key", ""),
                "shortIds": rs.get("short_ids", [""]),
                "fingerprint": rs.get("fingerprint", "chrome"),
                "spiderX": rs.get("spider_x", "/")
            }
        elif security == "tls":
            ts = raw_stream.get("tls_settings", {})
            stream_dict["tlsSettings"] = {
                "serverName": ts.get("server_name", ""),
                "certificates": []
            }

        # Network Specifics
        if network == "ws":
            stream_dict["wsSettings"] = {
                "path": raw_stream.get("ws_path", "/ws"),
                "headers": {}
            }
        elif network == "grpc":
            stream_dict["grpcSettings"] = {
                "serviceName": raw_stream.get("grpc_service_name", "grpc")
            }

        # Sniffing
        sniffing_dict = {
            "enabled": True,
            "destOverride": ["http", "tls", "quic"],
            "metadataOnly": False
        }

        xray_inbound = {
            "tag": ib.tag,
            "port": ib.port,
            "listen": ib.listen,
            "protocol": ib.protocol,
            "settings": inbound_settings,
            "streamSettings": stream_dict,
            "sniffing": sniffing_dict
        }
        xray_inbounds.append(xray_inbound)

    return {
        "log": {
            "access": "/opt/mehboobxt/logs/xray_access.log",
            "error": "/opt/mehboobxt/logs/xray_error.log",
            "loglevel": "warning"
        },
        "api": {
            "tag": "api",
            "services": ["HandlerService", "StatsService"]
        },
        "inbounds": xray_inbounds,
        "outbounds": [
            {"protocol": "freedom", "tag": "direct"},
            {"protocol": "blackhole", "tag": "blocked"}
        ],
        "routing": {
            "domainStrategy": "AsIs",
            "rules": [
                {"type": "field", "inboundTag": ["api"], "outboundTag": "api"}
            ]
        }
    }
PYEOF

log_info "Writing Xray Process Engine (${APP_DIR}/core/xray_engine.py)..."
cat << 'PYEOF' > "${APP_DIR}/core/xray_engine.py"
import os
import json
import shutil
import tempfile
import subprocess
from typing import Tuple, Dict, Any
from app.core.config import settings

class XrayEngine:
    @staticmethod
    def test_config(config_dict: Dict[str, Any]) -> Tuple[bool, str]:
        """Validates configuration against Xray binary without modifying production."""
        with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as tf:
            json.dump(config_dict, tf, indent=2)
            temp_path = tf.name

        try:
            cmd = [settings.xray_bin, "test", "-config", temp_path]
            proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=10)
            if proc.returncode == 0:
                return True, "Configuration validated successfully."
            return False, f"Xray test failed:\n{proc.stderr.strip() or proc.stdout.strip()}"
        except Exception as e:
            return False, f"Execution exception: {str(e)}"
        finally:
            if os.path.exists(temp_path):
                os.remove(temp_path)

    @staticmethod
    def apply_config(config_dict: Dict[str, Any]) -> Tuple[bool, str]:
        """Validates atomically, creates a backup, writes config, and reloads service."""
        is_valid, msg = XrayEngine.test_config(config_dict)
        if not is_valid:
            return False, msg

        # Backup current working configuration
        backup_path = f"{settings.xray_config}.bak"
        if os.path.exists(settings.xray_config):
            shutil.copy2(settings.xray_config, backup_path)

        # Atomic write
        temp_target = f"{settings.xray_config}.tmp"
        with open(temp_target, "w", encoding="utf-8") as f:
            json.dump(config_dict, f, indent=2)
        os.replace(temp_target, settings.xray_config)

        # Restart service
        restart_ok, restart_msg = XrayEngine.restart_service()
        if not restart_ok:
            # Rollback
            if os.path.exists(backup_path):
                shutil.copy2(backup_path, settings.xray_config)
                XrayEngine.restart_service()
            return False, f"Service restart failed, rolled back to previous config: {restart_msg}"

        return True, "Configuration applied and Xray reloaded successfully."

    @staticmethod
    def restart_service() -> Tuple[bool, str]:
        try:
            subprocess.run(["systemctl", "restart", "mehboobxt-xray.service"], check=True, capture_output=True, text=True)
            return True, "mehboobxt-xray restarted."
        except subprocess.CalledProcessError as e:
            return False, e.stderr.strip()

    @staticmethod
    def get_status() -> Dict[str, Any]:
        try:
            res = subprocess.run(["systemctl", "is-active", "mehboobxt-xray.service"], capture_output=True, text=True)
            is_active = (res.stdout.strip() == "active")
        except Exception:
            is_active = False

        return {
            "service": "mehboobxt-xray",
            "is_active": is_active,
            "binary_path": settings.xray_bin,
            "config_path": settings.xray_config
        }

    @staticmethod
    def generate_reality_keypair() -> Dict[str, str]:
        """Generates an X25519 Reality keypair using Xray binary."""
        try:
            proc = subprocess.run([settings.xray_bin, "x25519"], capture_output=True, text=True, check=True)
            lines = proc.stdout.strip().splitlines()
            priv, pub = "", ""
            for line in lines:
                if "PrivateKey:" in line or "Private key:" in line:
                    priv = line.split(":", 1)[1].strip()
                elif "PublicKey:" in line or "Public key:" in line:
                    pub = line.split(":", 1)[1].strip()
            return {"private_key": priv, "public_key": pub}
        except Exception as e:
            return {"error": str(e), "private_key": "", "public_key": ""}
PYEOF

# ------------------------------------------------------------------------------
# 4. Services: Xray Sync & Native SSH Linux Isolation
# ------------------------------------------------------------------------------
log_info "Writing Xray Service Logic (${APP_DIR}/services/xray_service.py)..."
cat << 'PYEOF' > "${APP_DIR}/services/xray_service.py"
import urllib.parse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import Dict, Any, List
from app.db.models import Inbound, Client
from app.core.xray_config import build_xray_config
from app.core.xray_engine import XrayEngine

class XrayService:
    @staticmethod
    async def sync_database_to_xray(db: AsyncSession) -> tuple[bool, str]:
        """Loads all inbounds & clients, builds config, and applies it safely."""
        inbounds_res = await db.execute(select(Inbound))
        inbounds = list(inbounds_res.scalars().all())

        clients_res = await db.execute(select(Client).filter_by(client_type="xray"))
        all_clients = list(clients_res.scalars().all())

        clients_map: Dict[int, List[Client]] = {}
        for cl in all_clients:
            if cl.inbound_id not in clients_map:
                clients_map[cl.inbound_id] = []
            clients_map[cl.inbound_id].append(cl)

        cfg_dict = build_xray_config(inbounds, clients_map)
        return XrayEngine.apply_config(cfg_dict)

    @staticmethod
    def generate_share_link(client: Client, inbound: Inbound, public_ip: str) -> str:
        """Generates standard vless://, vmess://, or trojan:// URI links."""
        try:
            import json
            raw_stream = json.loads(inbound.stream_settings_json) if inbound.stream_settings_json else {}
            net = raw_stream.get("network", "tcp")
            sec = raw_stream.get("security", "none")
            remark = f"{inbound.tag}-{client.email}"

            if inbound.protocol == "vless":
                params = {"type": net, "security": sec}
                if sec == "reality":
                    rs = raw_stream.get("reality_settings", {})
                    params["pbk"] = rs.get("public_key", "")
                    params["fp"] = rs.get("fingerprint", "chrome")
                    sns = rs.get("server_names", [""])
                    params["sni"] = sns[0] if sns else ""
                    sids = rs.get("short_ids", [""])
                    params["sid"] = sids[0] if sids else ""
                    params["spx"] = rs.get("spider_x", "/")
                if client.flow:
                    params["flow"] = client.flow
                query = urllib.parse.urlencode(params)
                return f"vless://{client.uuid}@{public_ip}:{inbound.port}?{query}#{urllib.parse.quote(remark)}"

            elif inbound.protocol == "trojan":
                params = {"type": net, "security": sec}
                query = urllib.parse.urlencode(params)
                return f"trojan://{client.uuid}@{public_ip}:{inbound.port}?{query}#{urllib.parse.quote(remark)}"

            return "protocol_unsupported_for_link"
        except Exception:
            return ""
PYEOF

log_info "Writing Native Linux SSH Subsystem (${APP_DIR}/services/ssh_service.py)..."
cat << 'PYEOF' > "${APP_DIR}/services/ssh_service.py"
import subprocess
import re
from datetime import datetime
from typing import Tuple, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.db.models import SSHTunnelUser

TUNNEL_SHELL = "/usr/local/bin/mehboobxt-tunnel-shell"
TUNNEL_GROUP = "mehboobxt_tunnel"

class SSHService:
    @staticmethod
    def validate_username(username: str) -> bool:
        return bool(re.match(r"^[a-zA-Z0-9_]{3,32}$", username))

    @staticmethod
    def create_system_user(username: str, password: str, expiry_date: datetime | None = None) -> Tuple[bool, str]:
        if not SSHService.validate_username(username):
            return False, "Invalid username format. Must be 3-32 alphanumeric characters."

        # useradd with no home directory creation, assigned to tunnel shell & group
        cmd = [
            "useradd",
            "-M",
            "-g", TUNNEL_GROUP,
            "-s", TUNNEL_SHELL,
            username
        ]
        try:
            subprocess.run(cmd, check=True, capture_output=True, text=True)
        except subprocess.CalledProcessError as e:
            return False, f"Failed to create Linux system user: {e.stderr.strip()}"

        # Safe password setting via stdin
        try:
            p = subprocess.Popen(["chpasswd"], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            stdout, stderr = p.communicate(input=f"{username}:{password}\n")
            if p.returncode != 0:
                return False, f"Failed to set system password: {stderr.strip()}"
        except Exception as e:
            return False, str(e)

        # Set account expiry if specified
        if expiry_date:
            exp_str = expiry_date.strftime("%Y-%m-%d")
            subprocess.run(["chage", "-E", exp_str, username], capture_output=True)

        return True, f"System user {username} provisioned successfully."

    @staticmethod
    def update_system_password(username: str, new_password: str) -> Tuple[bool, str]:
        if not SSHService.validate_username(username):
            return False, "Invalid username."
        try:
            p = subprocess.Popen(["chpasswd"], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            _, stderr = p.communicate(input=f"{username}:{new_password}\n")
            if p.returncode != 0:
                return False, stderr.strip()
            return True, "Password updated successfully."
        except Exception as e:
            return False, str(e)

    @staticmethod
    def toggle_user_lock(username: str, lock: bool) -> Tuple[bool, str]:
        flag = "-L" if lock else "-U"
        try:
            subprocess.run(["usermod", flag, username], check=True, capture_output=True, text=True)
            if lock:
                # Terminate any active sessions immediately
                subprocess.run(["pkill", "-u", username], capture_output=True)
            return True, f"User {username} {'locked' if lock else 'unlocked'}."
        except subprocess.CalledProcessError as e:
            return False, e.stderr.strip()

    @staticmethod
    def delete_system_user(username: str) -> Tuple[bool, str]:
        if not SSHService.validate_username(username):
            return False, "Invalid username."
        subprocess.run(["pkill", "-u", username], capture_output=True)
        try:
            subprocess.run(["userdel", username], check=True, capture_output=True, text=True)
            return True, f"User {username} deleted."
        except subprocess.CalledProcessError as e:
            return False, e.stderr.strip()
PYEOF

# ------------------------------------------------------------------------------
# 5. API Routers: Inbounds, Clients, Xray Management & SSH
# ------------------------------------------------------------------------------
log_info "Writing Xray Process API Router (${APP_DIR}/api/xray.py)..."
cat << 'PYEOF' > "${APP_DIR}/api/xray.py"
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.database import get_db
from app.db.models import Admin
from app.api.auth import get_current_admin
from app.core.xray_engine import XrayEngine
from app.services.xray_service import XrayService

router = APIRouter(prefix="/api/xray", tags=["Xray Engine"])

@router.get("/status")
async def get_status(_: Admin = Depends(get_current_admin)):
    return XrayEngine.get_status()

@router.post("/restart")
async def restart_xray(_: Admin = Depends(get_current_admin)):
    ok, msg = XrayEngine.restart_service()
    if not ok:
        raise HTTPException(status_code=500, detail=msg)
    return {"success": True, "message": msg}

@router.post("/sync")
async def sync_xray(db: AsyncSession = Depends(get_db), _: Admin = Depends(get_current_admin)):
    ok, msg = await XrayService.sync_database_to_xray(db)
    if not ok:
        raise HTTPException(status_code=400, detail=msg)
    return {"success": True, "message": msg}

@router.get("/reality/keypair")
async def get_reality_keypair(_: Admin = Depends(get_current_admin)):
    keys = XrayEngine.generate_reality_keypair()
    if not keys.get("private_key"):
        raise HTTPException(status_code=500, detail="Failed to generate keys via Xray binary.")
    return keys
PYEOF

log_info "Writing Inbounds API Router (${APP_DIR}/api/inbounds.py)..."
cat << 'PYEOF' > "${APP_DIR}/api/inbounds.py"
import json
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from typing import List
from app.db.database import get_db
from app.db.models import Admin, Inbound, Client
from app.api.auth import get_current_admin
from app.schemas.xray import InboundCreate, InboundUpdate, InboundResponse, StreamSettings
from app.services.xray_service import XrayService

router = APIRouter(prefix="/api/inbounds", tags=["Inbound Management"])

@router.get("", response_model=List[InboundResponse])
async def list_inbounds(db: AsyncSession = Depends(get_db), _: Admin = Depends(get_current_admin)):
    result = await db.execute(select(Inbound))
    inbounds = result.scalars().all()
    out = []
    for ib in inbounds:
        count_res = await db.execute(select(func.count(Client.id)).filter_by(inbound_id=ib.id))
        count = count_res.scalar() or 0
        stream_data = json.loads(ib.stream_settings_json) if ib.stream_settings_json else {}
        out.append(InboundResponse(
            id=ib.id,
            tag=ib.tag,
            protocol=ib.protocol,
            port=ib.port,
            listen=ib.listen,
            stream=StreamSettings(**stream_data),
            sniffing_enabled=True,
            up_bytes=ib.up_bytes,
            down_bytes=ib.down_bytes,
            total_limit_bytes=ib.total_limit_bytes,
            expiry_timestamp=ib.expiry_timestamp,
            is_enabled=ib.is_enabled,
            client_count=count
        ))
    return out

@router.post("", status_code=status.HTTP_201_CREATED)
async def create_inbound(
    payload: InboundCreate,
    db: AsyncSession = Depends(get_db),
    _: Admin = Depends(get_current_admin)
):
    # Verify port / tag conflict
    existing = await db.execute(select(Inbound).filter((Inbound.port == payload.port) | (Inbound.tag == payload.tag)))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Inbound port or tag already in use.")

    inbound = Inbound(
        tag=payload.tag,
        protocol=payload.protocol,
        port=payload.port,
        listen=payload.listen,
        stream_settings_json=json.dumps(payload.stream.model_dump()),
        sniffing_json=json.dumps({"enabled": payload.sniffing_enabled}),
        total_limit_bytes=payload.total_limit_bytes,
        expiry_timestamp=payload.expiry_timestamp,
        is_enabled=payload.is_enabled
    )
    db.add(inbound)
    await db.commit()
    await db.refresh(inbound)

    # Sync to Xray
    ok, msg = await XrayService.sync_database_to_xray(db)
    if not ok:
        await db.delete(inbound)
        await db.commit()
        raise HTTPException(status_code=400, detail=f"Xray rejection: {msg}")

    return {"success": True, "id": inbound.id, "message": "Inbound created and synced."}

@router.delete("/{inbound_id}")
async def delete_inbound(
    inbound_id: int,
    db: AsyncSession = Depends(get_db),
    _: Admin = Depends(get_current_admin)
):
    res = await db.execute(select(Inbound).filter_by(id=inbound_id))
    inbound = res.scalar_one_or_none()
    if not inbound:
        raise HTTPException(status_code=404, detail="Inbound not found")

    await db.delete(inbound)
    await db.commit()
    await XrayService.sync_database_to_xray(db)
    return {"success": True, "message": "Inbound removed and Xray re-synced."}
PYEOF

log_info "Writing Clients API Router (${APP_DIR}/api/clients.py)..."
cat << 'PYEOF' > "${APP_DIR}/api/clients.py"
import uuid as uuid_pkg
import socket
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List
from app.db.database import get_db
from app.db.models import Admin, Client, Inbound
from app.api.auth import get_current_admin
from app.schemas.xray import ClientCreate, ClientResponse, ClientUpdate
from app.services.xray_service import XrayService

router = APIRouter(prefix="/api/clients", tags=["Client Management"])

def get_server_ip() -> str:
    try:
        import httpx
        with httpx.Client(timeout=2.0) as client:
            return client.get("https://api.ipify.org").text.strip()
    except Exception:
        return "127.0.0.1"

@router.get("", response_model=List[ClientResponse])
async def list_clients(db: AsyncSession = Depends(get_db), _: Admin = Depends(get_current_admin)):
    res = await db.execute(select(Client).filter_by(client_type="xray"))
    clients = res.scalars().all()
    server_ip = get_server_ip()
    out = []
    for cl in clients:
        ib_res = await db.execute(select(Inbound).filter_by(id=cl.inbound_id))
        ib = ib_res.scalar_one_or_none()
        link = XrayService.generate_share_link(cl, ib, server_ip) if ib else ""
        out.append(ClientResponse(
            id=cl.id,
            inbound_id=cl.inbound_id,
            email=cl.email,
            uuid=cl.uuid,
            flow=cl.flow,
            up_bytes=cl.up_bytes,
            down_bytes=cl.down_bytes,
            total_limit_bytes=cl.total_limit_bytes,
            expiry_timestamp=cl.expiry_timestamp,
            is_enabled=cl.is_enabled,
            client_type=cl.client_type,
            share_link=link
        ))
    return out

@router.post("", status_code=status.HTTP_201_CREATED)
async def create_client(
    payload: ClientCreate,
    db: AsyncSession = Depends(get_db),
    _: Admin = Depends(get_current_admin)
):
    ib_res = await db.execute(select(Inbound).filter_by(id=payload.inbound_id))
    inbound = ib_res.scalar_one_or_none()
    if not inbound:
        raise HTTPException(status_code=404, detail="Referenced inbound does not exist.")

    existing_email = await db.execute(select(Client).filter_by(email=payload.email))
    if existing_email.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Client email already exists.")

    final_uuid = payload.uuid or str(uuid_pkg.uuid4())

    client = Client(
        inbound_id=payload.inbound_id,
        email=payload.email,
        uuid=final_uuid,
        flow=payload.flow or "",
        total_limit_bytes=payload.total_limit_bytes,
        expiry_timestamp=payload.expiry_timestamp,
        is_enabled=payload.is_enabled,
        client_type="xray"
    )
    db.add(client)
    await db.commit()
    await db.refresh(client)

    ok, msg = await XrayService.sync_database_to_xray(db)
    if not ok:
        await db.delete(client)
        await db.commit()
        raise HTTPException(status_code=400, detail=f"Xray rejected updated client: {msg}")

    return {"success": True, "id": client.id, "uuid": client.uuid, "message": "Client created successfully."}

@router.delete("/{client_id}")
async def delete_client(
    client_id: int,
    db: AsyncSession = Depends(get_db),
    _: Admin = Depends(get_current_admin)
):
    res = await db.execute(select(Client).filter_by(id=client_id))
    client = res.scalar_one_or_none()
    if not client:
        raise HTTPException(status_code=404, detail="Client not found")

    await db.delete(client)
    await db.commit()
    await XrayService.sync_database_to_xray(db)
    return {"success": True, "message": "Client removed successfully."}
PYEOF

log_info "Writing Native SSH API Router (${APP_DIR}/api/ssh.py)..."
cat << 'PYEOF' > "${APP_DIR}/api/ssh.py"
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List
from app.db.database import get_db
from app.db.models import Admin, SSHTunnelUser
from app.api.auth import get_current_admin
from app.schemas.ssh import SSHTunnelUserCreate, SSHTunnelUserUpdate, SSHTunnelUserResponse
from app.services.ssh_service import SSHService

router = APIRouter(prefix="/api/ssh/users", tags=["SSH Tunnel Subsystem"])

@router.get("", response_model=List[SSHTunnelUserResponse])
async def list_ssh_users(db: AsyncSession = Depends(get_db), _: Admin = Depends(get_current_admin)):
    res = await db.execute(select(SSHTunnelUser))
    return res.scalars().all()

@router.post("", status_code=status.HTTP_201_CREATED)
async def create_ssh_user(
    payload: SSHTunnelUserCreate,
    db: AsyncSession = Depends(get_db),
    _: Admin = Depends(get_current_admin)
):
    res = await db.execute(select(SSHTunnelUser).filter_by(username=payload.username))
    if res.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="SSH tunnel username already exists.")

    ok, msg = SSHService.create_system_user(payload.username, payload.password, payload.expiry_date)
    if not ok:
        raise HTTPException(status_code=400, detail=msg)

    user = SSHTunnelUser(
        username=payload.username,
        password=payload.password,
        expiry_date=payload.expiry_date,
        max_connections=payload.max_connections,
        is_active=payload.is_active
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)

    return {"success": True, "id": user.id, "message": f"User {user.username} created on system and database."}

@router.delete("/{user_id}")
async def delete_ssh_user(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    _: Admin = Depends(get_current_admin)
):
    res = await db.execute(select(SSHTunnelUser).filter_by(id=user_id))
    user = res.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    SSHService.delete_system_user(user.username)
    await db.delete(user)
    await db.commit()
    return {"success": True, "message": f"User {user.username} deleted from Linux system and DB."}
PYEOF

# ------------------------------------------------------------------------------
# 6. Master App & Systemd Update
# ------------------------------------------------------------------------------
log_info "Updating Application Entrypoint (${APP_DIR}/main.py)..."
cat << 'PYEOF' > "${APP_DIR}/main.py"
import os
import psutil
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.responses import JSONResponse
from sqlalchemy import select
from app.core.config import settings
from app.core.security import get_password_hash
from app.db.database import init_db, AsyncSessionLocal
from app.db.models import Admin
from app.services.xray_service import XrayService

# Routers
from app.api.auth import router as auth_router
from app.api.xray import router as xray_router
from app.api.inbounds import router as inbounds_router
from app.api.clients import router as clients_router
from app.api.ssh import router as ssh_router

async def seed_initial_admin():
    async with AsyncSessionLocal() as session:
        result = await session.execute(select(Admin))
        if not result.scalar_one_or_none():
            default_admin = Admin(
                username="admin",
                password_hash=get_password_hash("admin")
            )
            session.add(default_admin)
            await session.commit()
            print("[INFO] Initial admin account verified.")

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup sequence
    await init_db()
    await seed_initial_admin()
    async with AsyncSessionLocal() as session:
        # Sync initial state to Xray
        await XrayService.sync_database_to_xray(session)
    yield

app = FastAPI(
    title="MehboobXT Panel",
    description="High-Performance Enterprise VPS Management Panel (Xray & SSH)",
    version="3.0.0",
    lifespan=lifespan
)

# Register API Routers
app.include_router(auth_router)
app.include_router(xray_router)
app.include_router(inbounds_router)
app.include_router(clients_router)
app.include_router(ssh_router)

@app.get("/")
async def root():
    return {
        "status": "online",
        "panel": "MehboobXT Web Panel",
        "version": "3.0.0",
        "phase": "Phase 3 Operational (Xray Core + SSH Subsystem)",
        "features": [
            "VLESS-Reality",
            "VMess",
            "Trojan",
            "Native SSH Tunnel Isolation",
            "Deterministic Xray Sync"
        ],
        "endpoints": {
            "docs": "/docs",
            "health": "/health",
            "xray_status": "/api/xray/status",
            "inbounds": "/api/inbounds",
            "clients": "/api/clients",
            "ssh_users": "/api/ssh/users"
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
            "xray_binary_exists": os.path.isfile(settings.xray_bin),
            "db_path": settings.db_path
        }
    )
PYEOF

log_info "Configuring mehboobxt-xray.service systemd unit..."
cat << 'SYSTEMD_EOF' > "${XRAY_SERVICE_FILE}"
[Unit]
Description=MehboobXT Xray-Core Service
After=network.target network-online.target nss-lookup.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/mehboobxt
ExecStart=/opt/mehboobxt/bin/xray run -config /opt/mehboobxt/config/xray_config.json
Restart=always
RestartSec=3s
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
SYSTEMD_EOF

# ------------------------------------------------------------------------------
# 7. Updating Global CLI Utility
# ------------------------------------------------------------------------------
log_info "Updating Global CLI (${PANEL_DIR}/cli/mehboobxt.sh)..."
cat << 'SHELL_EOF' > "${PANEL_DIR}/cli/mehboobxt.sh"
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
SHELL_EOF

chmod +x "${PANEL_DIR}/cli/mehboobxt.sh"

# ------------------------------------------------------------------------------
# 8. Syntax Validation & Service Ignition
# ------------------------------------------------------------------------------
log_info "Validating Python compilation syntax..."
"${PYTHON_BIN}" -m py_compile \
    "${APP_DIR}/schemas/xray.py" \
    "${APP_DIR}/schemas/ssh.py" \
    "${APP_DIR}/core/xray_config.py" \
    "${APP_DIR}/core/xray_engine.py" \
    "${APP_DIR}/services/xray_service.py" \
    "${APP_DIR}/services/ssh_service.py" \
    "${APP_DIR}/api/xray.py" \
    "${APP_DIR}/api/inbounds.py" \
    "${APP_DIR}/api/clients.py" \
    "${APP_DIR}/api/ssh.py" \
    "${APP_DIR}/main.py"
log_success "All Python source files passed syntax check."

log_info "Reloading systemd daemons and restarting services..."
systemctl daemon-reload
systemctl enable mehboobxt-xray.service
systemctl restart mehboobxt.service
systemctl restart mehboobxt-xray.service

log_success "Phase 3 successfully deployed!"
