#!/usr/bin/env bash
# ==============================================================================
# MehboobXT VPS Panel - Phase 4 Final Fix Script
# Socket-Level Bind Validation, DB Cleanup & Runtime Sync
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

readonly REPO_DIR="/root/mehboobxt-panel"
readonly PANEL_DIR="/opt/mehboobxt"
readonly PYTHON_BIN="${PANEL_DIR}/venv/bin/python3"
readonly DB_FILE="${PANEL_DIR}/database/mehboobxt.db"
readonly XRAY_CONFIG="${PANEL_DIR}/config/xray_config.json"

readonly CYAN='\033[0;36m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

log_info()    { echo -e "${CYAN}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_fatal()   { echo -e "${RED}[FATAL]${NC} $1" >&2; exit 1; }

# Pre-flight root check
if [[ "$(id -u)" -ne 0 ]]; then
    log_fatal "This script must be executed as root."
fi

# Ensure Python virtual environment exists
if [[ ! -x "${PYTHON_BIN}" ]]; then
    log_fatal "Virtual environment Python not found at ${PYTHON_BIN}."
fi

# ------------------------------------------------------------------------------
# 1. Purge Conflicting Port 443 Record from SQLite Database
# ------------------------------------------------------------------------------
log_info "Auditing and purging conflicting port 443 records from SQLite database..."
"${PYTHON_BIN}" - << 'PY_CLEANUP'
import sqlite3
import sys

db_path = "/opt/mehboobxt/database/mehboobxt.db"

try:
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    # Find conflicting inbounds on port 443
    cur.execute("SELECT id, tag, port FROM inbounds WHERE port = 443 OR tag = '443'")
    conflicts = cur.fetchall()

    if conflicts:
        for ib_id, tag, port in conflicts:
            print(f"[INFO] Removing conflicting inbound ID {ib_id} (tag='{tag}', port={port})...")
            # Remove associated clients
            cur.execute("DELETE FROM clients WHERE inbound_id = ?", (ib_id,))
            # Remove inbound record
            cur.execute("DELETE FROM inbounds WHERE id = ?", (ib_id,))
        conn.commit()
        print("[OK] Conflicting port 443 records removed from database.")
    else:
        print("[INFO] No port 443 conflicts found in database.")

    # Confirm remaining inbounds
    cur.execute("SELECT id, tag, port FROM inbounds")
    remaining = cur.fetchall()
    print(f"[INFO] Remaining inbounds: {remaining}")

    conn.close()
except Exception as e:
    print(f"[ERROR] Database cleanup failed: {e}", file=sys.stderr)
    sys.exit(1)
PY_CLEANUP
log_success "Database cleanup completed."

# ------------------------------------------------------------------------------
# 2. Patch app/api/inbounds.py with Socket-Level Validation
# ------------------------------------------------------------------------------
log_info "Patching ${REPO_DIR}/app/api/inbounds.py with pre-flight socket validation..."
cat << 'PY_INBOUNDS' > "${REPO_DIR}/app/api/inbounds.py"
import json
import socket
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

def verify_socket_bindable(port: int, host: str = "0.0.0.0") -> tuple[bool, str]:
    """
    Performs active Linux TCP socket pre-flight checks across IPv4 and IPv6
    to prevent EADDRINUSE collisions before modifying DB or Xray.
    """
    # 1. System Reserved Ports Check
    if port in (22, 80, 443, 2053):
        return False, f"Port {port} is reserved by system daemons (SSH/Web/Nginx/Panel)."

    # 2. IPv4 Socket Binding Probe
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as probe_s4:
            probe_s4.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            probe_s4.bind((host if host != "::" else "0.0.0.0", port))
    except OSError as e:
        return False, f"TCP port {port} is already bound by another process: {e.strerror}"

    # 3. IPv6 Socket Binding Probe (for wildcard bindings)
    if host in ("0.0.0.0", "::"):
        try:
            with socket.socket(socket.AF_INET6, socket.SOCK_STREAM) as probe_s6:
                probe_s6.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
                probe_s6.bind(("::", port))
        except OSError as e:
            if e.errno == 98 or "already in use" in str(e).lower():
                return False, f"TCP port {port} (IPv6) is already bound by another process: {e.strerror}"
        except Exception:
            pass

    return True, ""

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
    # Step A: Pre-flight OS Kernel Socket Binding Check
    is_bindable, reason = verify_socket_bindable(payload.port, payload.listen)
    if not is_bindable:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Port collision: {reason}. Choose an available port (e.g. 10000-60000)."
        )

    # Step B: Database Tag and Port Collision Check
    existing = await db.execute(
        select(Inbound).filter((Inbound.port == payload.port) | (Inbound.tag == payload.tag))
    )
    if existing.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Inbound with port {payload.port} or tag '{payload.tag}' already exists in database."
        )

    # Step C: Write Inbound to Database
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

    # Step D: Atomic Sync & Reload Xray Service
    ok, msg = await XrayService.sync_database_to_xray(db)
    if not ok:
        await db.delete(inbound)
        await db.commit()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Xray core validation rejected configuration: {msg}"
        )

    return {"success": True, "id": inbound.id, "message": "Inbound created and synced successfully."}

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
    return {"success": True, "message": "Inbound removed and Xray configuration re-synced."}
PY_INBOUNDS
log_success "Patched app/api/inbounds.py."

# ------------------------------------------------------------------------------
# 3. Patch app/static/js/app.js (Default Port 10000 + Port Validation)
# ------------------------------------------------------------------------------
log_info "Patching ${REPO_DIR}/app/static/js/app.js to remove port 443 default..."
cat << 'JS_PATCH' > "${REPO_DIR}/app/static/js/app.js"
function panelAppData() {
    return {
        currentTab: 'overview',
        mobileMenuOpen: false,
        systemInfo: { cpu: 0, ram: 0, disk: 0, xray_status: 'loading' },
        inbounds: [],
        clients: [],
        sshUsers: [],
        loading: false,
        toast: { show: false, message: '', type: 'success' },

        modalInbound: false,
        modalClient: false,
        modalSSH: false,
        modalShare: { show: false, link: '', title: '' },

        // Inbound Form with default port 10000 (prevents 443 web collision)
        newInbound: {
            tag: '',
            protocol: 'vless',
            port: 10000,
            listen: '0.0.0.0',
            stream: {
                network: 'tcp',
                security: 'reality',
                reality_settings: {
                    dest: 'www.microsoft.com:443',
                    server_names: ['www.microsoft.com'],
                    private_key: '',
                    public_key: '',
                    short_ids: ['abcd1234'],
                    fingerprint: 'chrome',
                    spider_x: '/'
                }
            }
        },

        newClient: {
            inbound_id: '',
            email: '',
            flow: 'xtls-rprx-vision'
        },

        newSSH: {
            username: '',
            password: '',
            max_connections: 2
        },

        init() {
            this.fetchHealth();
            this.fetchInbounds();
            this.fetchClients();
            this.fetchSSHUsers();
            setInterval(() => this.fetchHealth(), 5000);
        },

        notify(msg, type = 'success') {
            this.toast = { show: true, message: msg, type: type };
            setTimeout(() => { this.toast.show = false; }, 4000);
        },

        async fetchHealth() {
            try {
                const res = await fetch('/health');
                if (res.status === 401) {
                    window.location.href = '/login';
                    return;
                }
                const data = await res.json();
                if (data && data.system) {
                    this.systemInfo.cpu = data.system.cpu_usage_percent ?? 0;
                    this.systemInfo.ram = data.system.ram_usage_percent ?? 0;
                    this.systemInfo.disk = data.system.disk_usage_percent ?? 0;
                }

                const xrayRes = await fetch('/api/xray/status');
                if (xrayRes.ok) {
                    const xrayData = await xrayRes.json();
                    this.systemInfo.xray_status = xrayData.is_active ? 'running' : 'stopped';
                }
            } catch (e) {
                console.error("Telemetry fetch error:", e);
            }
        },

        async fetchInbounds() {
            try {
                const res = await fetch('/api/inbounds');
                if (res.status === 401) { window.location.href = '/login'; return; }
                if (!res.ok) { this.notify("Failed to fetch inbounds", "error"); return; }
                this.inbounds = await res.json();
                if (this.inbounds.length > 0 && !this.newClient.inbound_id) {
                    this.newClient.inbound_id = this.inbounds[0].id;
                }
            } catch (e) {
                console.error("Inbounds error:", e);
            }
        },

        async fetchClients() {
            try {
                const res = await fetch('/api/clients');
                if (res.status === 401) { window.location.href = '/login'; return; }
                if (!res.ok) { this.notify("Failed to fetch clients", "error"); return; }
                this.clients = await res.json();
            } catch (e) {
                console.error("Clients error:", e);
            }
        },

        async fetchSSHUsers() {
            try {
                const res = await fetch('/api/ssh/users');
                if (res.status === 401) { window.location.href = '/login'; return; }
                if (!res.ok) { this.notify("Failed to fetch SSH users", "error"); return; }
                this.sshUsers = await res.json();
            } catch (e) {
                console.error("SSH users error:", e);
            }
        },

        async generateRealityKeys() {
            try {
                const res = await fetch('/api/xray/reality/keypair');
                if (res.status === 401) { window.location.href = '/login'; return; }
                const data = await res.json();
                if (data.private_key) {
                    this.newInbound.stream.reality_settings.private_key = data.private_key;
                    this.newInbound.stream.reality_settings.public_key = data.public_key;
                    this.notify("Generated new Reality Keypair!");
                } else {
                    this.notify("Failed to generate keys: " + (data.detail || "unknown"), "error");
                }
            } catch (e) {
                this.notify("Failed to generate keys", "error");
            }
        },

        openInboundModal() {
            this.modalInbound = true;
            if (!this.newInbound.port || this.newInbound.port === 443) {
                this.newInbound.port = 10000;
            }
            if (this.newInbound.stream.security === 'reality' && !this.newInbound.stream.reality_settings.private_key) {
                this.generateRealityKeys();
            }
        },

        async submitInbound() {
            const portNum = Number(this.newInbound.port);

            // Client-Side Port Validation
            if (!portNum || isNaN(portNum)) {
                this.notify("Port must be a valid number.", "error");
                return;
            }
            if (portNum < 1 || portNum > 65535) {
                this.notify("Port must be between 1 and 65535.", "error");
                return;
            }
            if ([22, 80, 443, 2053].includes(portNum)) {
                this.notify(`Port ${portNum} is reserved by the server (SSH/Nginx/Web/Panel). Use port 10000+`, "error");
                return;
            }
            const collision = this.inbounds.find(ib => Number(ib.port) === portNum);
            if (collision) {
                this.notify(`Port ${portNum} is already assigned to inbound '${collision.tag}'.`, "error");
                return;
            }

            this.loading = true;
            try {
                const payload = JSON.parse(JSON.stringify(this.newInbound));
                if (payload.stream.security !== 'reality') {
                    payload.stream.reality_settings = null;
                } else {
                    if (!payload.stream.reality_settings.private_key || !payload.stream.reality_settings.public_key) {
                        this.notify("Please generate or provide Reality keys.", "error");
                        this.loading = false;
                        return;
                    }
                }
                const res = await fetch('/api/inbounds', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(payload)
                });
                const data = await res.json();
                if (res.ok) {
                    this.notify("Inbound Created & Xray Synced!");
                    this.modalInbound = false;
                    this.fetchInbounds();
                } else {
                    this.notify(data.detail || "Error creating inbound", "error");
                }
            } catch (e) {
                this.notify("Request error: " + e.message, "error");
            } finally {
                this.loading = false;
            }
        },

        async deleteInbound(id) {
            if (!confirm("Are you sure you want to delete this inbound?")) return;
            try {
                const res = await fetch(`/api/inbounds/${id}`, { method: 'DELETE' });
                if (res.status === 401) { window.location.href = '/login'; return; }
                if (res.ok) {
                    this.notify("Inbound Deleted");
                    this.fetchInbounds();
                    this.fetchClients();
                } else {
                    const data = await res.json();
                    this.notify(data.detail || "Failed to delete inbound", "error");
                }
            } catch (e) { this.notify("Failed to delete", "error"); }
        },

        async submitClient() {
            if (!this.newClient.inbound_id) {
                this.notify("Please select an Inbound", "error");
                return;
            }
            if (!this.newClient.email) {
                this.notify("Please enter an email", "error");
                return;
            }
            this.loading = true;
            try {
                const payload = {
                    inbound_id: Number(this.newClient.inbound_id),
                    email: this.newClient.email.trim(),
                    flow: this.newClient.flow || ""
                };
                const res = await fetch('/api/clients', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(payload)
                });
                const data = await res.json();
                if (res.ok) {
                    this.notify("Client Added Successfully!");
                    this.modalClient = false;
                    this.newClient.email = "";
                    this.fetchClients();
                } else {
                    this.notify(data.detail || "Error adding client", "error");
                }
            } catch (e) {
                this.notify("Request error: " + e.message, "error");
            } finally {
                this.loading = false;
            }
        },

        async deleteClient(id) {
            if (!confirm("Delete this client?")) return;
            try {
                const res = await fetch(`/api/clients/${id}`, { method: 'DELETE' });
                if (res.status === 401) { window.location.href = '/login'; return; }
                if (res.ok) {
                    this.notify("Client deleted");
                    this.fetchClients();
                } else {
                    const data = await res.json();
                    this.notify(data.detail || "Failed to delete client", "error");
                }
            } catch (e) { this.notify("Failed to delete client", "error"); }
        },

        async submitSSH() {
            if (!this.newSSH.username || !this.newSSH.password) {
                this.notify("Username and password are required", "error");
                return;
            }
            this.loading = true;
            try {
                const payload = {
                    username: this.newSSH.username.trim(),
                    password: this.newSSH.password,
                    max_connections: Number(this.newSSH.max_connections || 2)
                };
                const res = await fetch('/api/ssh/users', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(payload)
                });
                const data = await res.json();
                if (res.ok) {
                    this.notify("SSH Tunnel User Provisioned!");
                    this.modalSSH = false;
                    this.newSSH = { username: '', password: '', max_connections: 2 };
                    this.fetchSSHUsers();
                } else {
                    this.notify(data.detail || "Error creating SSH user", "error");
                }
            } catch (e) {
                this.notify("Request error: " + e.message, "error");
            } finally {
                this.loading = false;
            }
        },

        async deleteSSHUser(id) {
            if (!confirm("Delete this SSH user?")) return;
            try {
                const res = await fetch(`/api/ssh/users/${id}`, { method: 'DELETE' });
                if (res.status === 401) { window.location.href = '/login'; return; }
                if (res.ok) {
                    this.notify("SSH user deleted");
                    this.fetchSSHUsers();
                } else {
                    const data = await res.json();
                    this.notify(data.detail || "Failed to delete SSH user", "error");
                }
            } catch (e) { this.notify("Failed to delete", "error"); }
        },

        showShare(title, link) {
            this.modalShare = { show: true, title: title, link: link };
            this.$nextTick(() => {
                const container = document.getElementById("qrcode");
                if (container) {
                    container.innerHTML = "";
                    try {
                        if (typeof QRCode !== 'undefined' && link) {
                            new QRCode(container, {
                                text: link,
                                width: 192,
                                height: 192,
                                colorDark: "#000000",
                                colorLight: "#ffffff",
                                correctLevel: (typeof QRCode !== 'undefined' && QRCode.CorrectLevel) ? QRCode.CorrectLevel.M : 0
                            });
                        } else {
                            container.innerHTML = "<div class='text-xs text-slate-500 py-4 font-mono'>QR preview unavailable.<br>Use Copy Link below.</div>";
                        }
                    } catch (err) {
                        console.warn("QR render error (non-fatal):", err);
                        container.innerHTML = "<div class='text-xs text-slate-500 py-4 font-mono'>QR preview unavailable.<br>Use Copy Link below.</div>";
                    }
                }
            });
        },

        copyToClipboard(text) {
            if (!text) {
                this.notify("No link available to copy", "error");
                return;
            }
            if (navigator.clipboard && navigator.clipboard.writeText) {
                navigator.clipboard.writeText(text).then(() => {
                    this.notify("Copied to clipboard!");
                }).catch(() => {
                    this.fallbackCopy(text);
                });
            } else {
                this.fallbackCopy(text);
            }
        },

        fallbackCopy(text) {
            const ta = document.createElement("textarea");
            ta.value = text;
            ta.style.position = "fixed";
            ta.style.left = "-9999px";
            document.body.appendChild(ta);
            ta.select();
            try {
                document.execCommand("copy");
                this.notify("Copied to clipboard!");
            } catch (e) {
                this.notify("Failed to copy automatically", "error");
            }
            document.body.removeChild(ta);
        },

        async logout() {
            try {
                await fetch('/api/auth/logout', { method: 'POST' });
            } finally {
                window.location.href = '/login';
            }
        }
    };
}

// Deterministic Alpine Lifecycle Hooks
document.addEventListener('alpine:init', () => {
    Alpine.data('panelApp', panelAppData);
});

if (window.Alpine) {
    window.Alpine.data('panelApp', panelAppData);
}

window.panelApp = panelAppData;
JS_PATCH
log_success "Patched app/static/js/app.js."

# ------------------------------------------------------------------------------
# 4. Copy Patched Files to Live Runtime /opt/mehboobxt/
# ------------------------------------------------------------------------------
log_info "Synchronizing patched files from ${REPO_DIR} to ${PANEL_DIR}..."
cp -p "${REPO_DIR}/app/api/inbounds.py" "${PANEL_DIR}/app/api/inbounds.py"
cp -p "${REPO_DIR}/app/static/js/app.js" "${PANEL_DIR}/app/static/js/app.js"
log_success "Runtime synchronization completed."

# ------------------------------------------------------------------------------
# 5. Synchronize Database State to Xray Configuration JSON
# ------------------------------------------------------------------------------
log_info "Synchronizing database to ${XRAY_CONFIG}..."
(cd "${PANEL_DIR}" && "${PYTHON_BIN}" - << 'PY_SYNC'
import asyncio
from app.db.database import AsyncSessionLocal
from app.services.xray_service import XrayService

async def main():
    async with AsyncSessionLocal() as session:
        ok, msg = await XrayService.sync_database_to_xray(session)
        if not ok:
            print(f"[FATAL] Config sync failed: {msg}")
            exit(1)
        print(f"[OK] {msg}")

asyncio.run(main())
PY_SYNC
)
log_success "Xray configuration rebuilt without port 443 conflicts."

# ------------------------------------------------------------------------------
# 6. Execute Strict Verification Chain
# ------------------------------------------------------------------------------
log_info "Validating Python compilation..."
"${PYTHON_BIN}" -m py_compile \
    "${PANEL_DIR}/app/main.py" \
    "${PANEL_DIR}/app/api/inbounds.py" \
    "${PANEL_DIR}/app/services/xray_service.py"
log_success "Python compilation OK."

log_info "Executing Xray core test on active configuration..."
"${PANEL_DIR}/bin/xray" run -test -config "${XRAY_CONFIG}"
log_success "Xray configuration passed validation."

log_info "Restarting systemd services..."
systemctl daemon-reload
systemctl restart mehboobxt.service
systemctl restart mehboobxt-xray.service

log_info "Checking service status..."
if systemctl is-active --quiet mehboobxt.service; then
    log_success "mehboobxt.service: active"
else
    log_fatal "mehboobxt.service failed to start."
fi

if systemctl is-active --quiet mehboobxt-xray.service; then
    log_success "mehboobxt-xray.service: active"
else
    log_fatal "mehboobxt-xray.service failed to start."
fi

echo ""
echo -e "${GREEN}====================================================${NC}"
echo -e "${GREEN}  PHASE 4 FINAL FIX SUCCESSFULLY DEPLOYED!           ${NC}"
echo -e "${GREEN}  Both mehboobxt and mehboobxt-xray are ACTIVE.     ${NC}"
echo -e "${GREEN}====================================================${NC}"
