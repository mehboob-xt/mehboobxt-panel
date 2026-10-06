#!/usr/bin/env bash
# ==============================================================================
# MehboobXT VPS Panel - Phase 4 Standalone Deployment Script
# Responsive Web GUI Frontend (Tailwind CSS + Alpine.js + Jinja2)
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

readonly PANEL_DIR="/opt/mehboobxt"
readonly APP_DIR="${PANEL_DIR}/app"
readonly REPO_DIR="/root/mehboobxt-panel"
readonly VENV_PYTHON="${PANEL_DIR}/venv/bin/python3"

readonly CYAN='\033[0;36m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

log_info()    { echo -e "${CYAN}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_fatal()   { echo -e "${RED}[FATAL]${NC} $1" >&2; exit 1; }

# Pre-flight check
if [[ "$(id -u)" -ne 0 ]]; then
    log_fatal "Must be run as root."
fi

# Verify Python Virtual Environment
if [[ ! -x "${VENV_PYTHON}" ]]; then
    log_fatal "Virtual environment Python not found or not executable at ${VENV_PYTHON}."
fi

# ------------------------------------------------------------------------------
# 1. Install Dependencies Inside Virtualenv
# ------------------------------------------------------------------------------
log_info "Installing Phase 4 Python dependencies (psutil, jinja2) inside virtualenv..."
"${VENV_PYTHON}" -m pip install psutil jinja2
log_success "Virtualenv dependencies installed."

# ------------------------------------------------------------------------------
# 2. Prepare Directories
# ------------------------------------------------------------------------------
log_info "Creating frontend directories in ${APP_DIR}..."
mkdir -p "${APP_DIR}/templates" "${APP_DIR}/static/css" "${APP_DIR}/static/js"

# ------------------------------------------------------------------------------
# 3. Custom CSS
# ------------------------------------------------------------------------------
log_info "Writing ${APP_DIR}/static/css/custom.css..."
cat << 'CSS_EOF' > "${APP_DIR}/static/css/custom.css"
[x-cloak] { display: none !important; }
::-webkit-scrollbar { width: 6px; height: 6px; }
::-webkit-scrollbar-track { background: #0f172a; }
::-webkit-scrollbar-thumb { background: #334155; border-radius: 3px; }
::-webkit-scrollbar-thumb:hover { background: #475569; }
CSS_EOF

# ------------------------------------------------------------------------------
# 4. Alpine.js Controller
# ------------------------------------------------------------------------------
log_info "Writing ${APP_DIR}/static/js/app.js..."
cat << 'JS_EOF' > "${APP_DIR}/static/js/app.js"
document.addEventListener('alpine:init', () => {
    Alpine.data('panelApp', () => ({
        currentTab: 'overview',
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

        newInbound: {
            tag: '',
            protocol: 'vless',
            port: 443,
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
            uuid: '',
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
                const data = await res.json();
                this.systemInfo.cpu = data.system.cpu_usage_percent;
                this.systemInfo.ram = data.system.ram_usage_percent;
                this.systemInfo.disk = data.system.disk_usage_percent;

                const xrayRes = await fetch('/api/xray/status');
                if (xrayRes.ok) {
                    const xrayData = await xrayRes.json();
                    this.systemInfo.xray_status = xrayData.is_active ? 'running' : 'stopped';
                }
            } catch (e) {
                console.error("Telemetry fetch error", e);
            }
        },

        async fetchInbounds() {
            try {
                const res = await fetch('/api/inbounds');
                if (res.status === 401) return window.location.href = '/login';
                this.inbounds = await res.json();
            } catch (e) { console.error(e); }
        },

        async fetchClients() {
            try {
                const res = await fetch('/api/clients');
                if (res.status === 401) return window.location.href = '/login';
                this.clients = await res.json();
            } catch (e) { console.error(e); }
        },

        async fetchSSHUsers() {
            try {
                const res = await fetch('/api/ssh/users');
                if (res.status === 401) return window.location.href = '/login';
                this.sshUsers = await res.json();
            } catch (e) { console.error(e); }
        },

        async generateRealityKeys() {
            try {
                const res = await fetch('/api/xray/reality/keypair');
                const data = await res.json();
                if (data.private_key) {
                    this.newInbound.stream.reality_settings.private_key = data.private_key;
                    this.newInbound.stream.reality_settings.public_key = data.public_key;
                    this.notify("Generated new Reality Keypair!");
                }
            } catch (e) {
                this.notify("Failed to generate keys", "error");
            }
        },

        async submitInbound() {
            this.loading = true;
            try {
                const res = await fetch('/api/inbounds', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(this.newInbound)
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
                this.notify("Request error", "error");
            } finally {
                this.loading = false;
            }
        },

        async deleteInbound(id) {
            if (!confirm("Are you sure you want to delete this inbound?")) return;
            try {
                const res = await fetch(`/api/inbounds/${id}`, { method: 'DELETE' });
                if (res.ok) {
                    this.notify("Inbound Deleted");
                    this.fetchInbounds();
                    this.fetchClients();
                }
            } catch (e) { this.notify("Failed to delete", "error"); }
        },

        async submitClient() {
            this.loading = true;
            try {
                const res = await fetch('/api/clients', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(this.newClient)
                });
                const data = await res.json();
                if (res.ok) {
                    this.notify("Client Added Successfully!");
                    this.modalClient = false;
                    this.fetchClients();
                } else {
                    this.notify(data.detail || "Error adding client", "error");
                }
            } catch (e) { this.notify("Request failed", "error"); }
            finally { this.loading = false; }
        },

        async deleteClient(id) {
            if (!confirm("Delete this client?")) return;
            try {
                const res = await fetch(`/api/clients/${id}`, { method: 'DELETE' });
                if (res.ok) {
                    this.notify("Client deleted");
                    this.fetchClients();
                }
            } catch (e) { this.notify("Failed to delete client", "error"); }
        },

        async submitSSH() {
            this.loading = true;
            try {
                const res = await fetch('/api/ssh/users', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(this.newSSH)
                });
                const data = await res.json();
                if (res.ok) {
                    this.notify("SSH Tunnel User Created!");
                    this.modalSSH = false;
                    this.newSSH = { username: '', password: '', max_connections: 2 };
                    this.fetchSSHUsers();
                } else {
                    this.notify(data.detail || "Error creating SSH user", "error");
                }
            } catch (e) { this.notify("Request failed", "error"); }
            finally { this.loading = false; }
        },

        async deleteSSHUser(id) {
            if (!confirm("Delete this SSH user?")) return;
            try {
                const res = await fetch(`/api/ssh/users/${id}`, { method: 'DELETE' });
                if (res.ok) {
                    this.notify("SSH user deleted");
                    this.fetchSSHUsers();
                }
            } catch (e) { this.notify("Failed to delete", "error"); }
        },

        showShare(title, link) {
            this.modalShare = { show: true, title: title, link: link };
            this.$nextTick(() => {
                const container = document.getElementById("qrcode");
                if (container) {
                    container.innerHTML = "";
                    if (window.QRCode && link) {
                        new QRCode(container, {
                            text: link,
                            width: 192,
                            height: 192,
                            colorDark: "#000000",
                            colorLight: "#ffffff",
                            correctLevel: QRCode.CorrectLevel.M
                        });
                    }
                }
            });
        },

        copyToClipboard(text) {
            navigator.clipboard.writeText(text);
            this.notify("Copied to clipboard!");
        },

        async logout() {
            await fetch('/api/auth/logout', { method: 'POST' });
            window.location.href = '/login';
        }
    }));
});
JS_EOF

# ------------------------------------------------------------------------------
# 5. Base Layout Template
# ------------------------------------------------------------------------------
log_info "Writing ${APP_DIR}/templates/base.html..."
cat << 'BASE_HTML_EOF' > "${APP_DIR}/templates/base.html"
<!DOCTYPE html>
<html lang="en" class="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{% block title %}MehboobXT Panel{% endblock %}</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            darkMode: 'class',
            theme: {
                extend: {
                    colors: {
                        brand: {
                            50: '#eef2ff',
                            500: '#6366f1',
                            600: '#4f46e5',
                            700: '#4338ca',
                            900: '#312e81'
                        }
                    }
                }
            }
        }
    </script>
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.13.5/dist/cdn.min.js"></script>
    <script src="https://unpkg.com/@phosphor-icons/web"></script>
    <script src="https://cdn.jsdelivr.net/npm/qrcodejs@1.0.0/qrcode.min.js"></script>
    <link rel="stylesheet" href="/static/css/custom.css">
</head>
<body class="bg-slate-950 text-slate-100 min-h-screen antialiased flex flex-col font-sans">
    {% block content %}{% endblock %}
</body>
</html>
BASE_HTML_EOF

# ------------------------------------------------------------------------------
# 6. Login View Template
# ------------------------------------------------------------------------------
log_info "Writing ${APP_DIR}/templates/login.html..."
cat << 'LOGIN_HTML_EOF' > "${APP_DIR}/templates/login.html"
{% extends "base.html" %}
{% block title %}Login - MehboobXT Panel{% endblock %}
{% block content %}
<div class="flex items-center justify-center min-h-screen px-4 bg-gradient-to-br from-slate-950 via-slate-900 to-indigo-950" x-data="{ username: '', password: '', error: '', loading: false }">
    <div class="w-full max-w-md p-8 bg-slate-900/80 backdrop-blur-xl border border-slate-800 rounded-2xl shadow-2xl shadow-indigo-950/50">
        <div class="text-center mb-8">
            <div class="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-indigo-600/20 text-indigo-400 mb-4 border border-indigo-500/30">
                <i class="ph-bold ph-shield-check text-3xl"></i>
            </div>
            <h1 class="text-2xl font-bold tracking-tight text-white">MehboobXT Panel</h1>
            <p class="text-sm text-slate-400 mt-1">Enterprise VPS & Proxy Manager</p>
        </div>

        <div x-show="error" x-text="error" class="mb-4 p-3 rounded-lg bg-rose-500/10 border border-rose-500/20 text-rose-400 text-sm font-medium"></div>

        <form @submit.prevent="
            loading = true; error = '';
            fetch('/api/auth/login', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ username, password })
            })
            .then(res => res.json().then(data => ({ status: res.status, data })))
            .then(res => {
                if (res.status === 200) {
                    window.location.href = '/dashboard';
                } else {
                    error = res.data.detail || 'Authentication failed';
                }
            })
            .catch(() => error = 'Connection error')
            .finally(() => loading = false);
        " class="space-y-5">
            <div>
                <label class="block text-xs font-semibold uppercase tracking-wider text-slate-400 mb-2">Username</label>
                <div class="relative">
                    <span class="absolute inset-y-0 left-0 flex items-center pl-3 text-slate-500"><i class="ph ph-user text-lg"></i></span>
                    <input type="text" x-model="username" required class="w-full pl-10 pr-4 py-2.5 bg-slate-800/80 border border-slate-700/80 rounded-xl text-white placeholder-slate-500 focus:outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 transition-all text-sm" placeholder="admin">
                </div>
            </div>

            <div>
                <label class="block text-xs font-semibold uppercase tracking-wider text-slate-400 mb-2">Password</label>
                <div class="relative">
                    <span class="absolute inset-y-0 left-0 flex items-center pl-3 text-slate-500"><i class="ph ph-lock text-lg"></i></span>
                    <input type="password" x-model="password" required class="w-full pl-10 pr-4 py-2.5 bg-slate-800/80 border border-slate-700/80 rounded-xl text-white placeholder-slate-500 focus:outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 transition-all text-sm" placeholder="••••••••">
                </div>
            </div>

            <button type="submit" :disabled="loading" class="w-full py-3 px-4 bg-indigo-600 hover:bg-indigo-500 disabled:opacity-50 text-white font-semibold rounded-xl shadow-lg shadow-indigo-600/30 transition-all text-sm flex items-center justify-center space-x-2">
                <span x-show="!loading">Sign In</span>
                <span x-show="loading" class="flex items-center space-x-2">
                    <i class="ph ph-spinner animate-spin"></i>
                    <span>Authenticating...</span>
                </span>
            </button>
        </form>
    </div>
</div>
{% endblock %}
LOGIN_HTML_EOF

# ------------------------------------------------------------------------------
# 7. Dashboard View Template
# ------------------------------------------------------------------------------
log_info "Writing ${APP_DIR}/templates/dashboard.html..."
cat << 'DASHBOARD_HTML_EOF' > "${APP_DIR}/templates/dashboard.html"
{% extends "base.html" %}
{% block title %}Dashboard - MehboobXT Panel{% endblock %}
{% block content %}
<div x-data="panelApp" class="flex h-screen overflow-hidden bg-slate-950">
    <aside class="w-64 bg-slate-900/90 border-r border-slate-800/80 flex flex-col justify-between p-4 z-20">
        <div>
            <div class="flex items-center space-x-3 px-2 py-4 mb-6">
                <div class="w-10 h-10 rounded-xl bg-indigo-600/20 text-indigo-400 flex items-center justify-center border border-indigo-500/30">
                    <i class="ph-bold ph-shield-check text-2xl"></i>
                </div>
                <div>
                    <h2 class="font-bold text-base text-white">MehboobXT</h2>
                    <span class="text-xs text-indigo-400 font-medium">Enterprise v4.0</span>
                </div>
            </div>

            <nav class="space-y-1.5">
                <button @click="currentTab = 'overview'" :class="currentTab === 'overview' ? 'bg-indigo-600/20 text-indigo-400 border border-indigo-500/30' : 'text-slate-400 hover:bg-slate-800/60 hover:text-slate-200'" class="w-full flex items-center space-x-3 px-3.5 py-2.5 rounded-xl font-medium text-sm transition-all">
                    <i class="ph ph-squares-four text-lg"></i>
                    <span>Overview</span>
                </button>
                <button @click="currentTab = 'inbounds'" :class="currentTab === 'inbounds' ? 'bg-indigo-600/20 text-indigo-400 border border-indigo-500/30' : 'text-slate-400 hover:bg-slate-800/60 hover:text-slate-200'" class="w-full flex items-center space-x-3 px-3.5 py-2.5 rounded-xl font-medium text-sm transition-all">
                    <i class="ph ph-arrows-in-cardinal text-lg"></i>
                    <span>Inbounds</span>
                </button>
                <button @click="currentTab = 'clients'" :class="currentTab === 'clients' ? 'bg-indigo-600/20 text-indigo-400 border border-indigo-500/30' : 'text-slate-400 hover:bg-slate-800/60 hover:text-slate-200'" class="w-full flex items-center space-x-3 px-3.5 py-2.5 rounded-xl font-medium text-sm transition-all">
                    <i class="ph ph-users text-lg"></i>
                    <span>Xray Clients</span>
                </button>
                <button @click="currentTab = 'ssh'" :class="currentTab === 'ssh' ? 'bg-indigo-600/20 text-indigo-400 border border-indigo-500/30' : 'text-slate-400 hover:bg-slate-800/60 hover:text-slate-200'" class="w-full flex items-center space-x-3 px-3.5 py-2.5 rounded-xl font-medium text-sm transition-all">
                    <i class="ph ph-terminal-window text-lg"></i>
                    <span>SSH Tunnels</span>
                </button>
            </nav>
        </div>

        <div class="border-t border-slate-800/80 pt-4">
            <button @click="logout()" class="w-full flex items-center space-x-3 px-3.5 py-2.5 text-rose-400 hover:bg-rose-500/10 rounded-xl font-medium text-sm transition-all">
                <i class="ph ph-sign-out text-lg"></i>
                <span>Sign Out</span>
            </button>
        </div>
    </aside>

    <main class="flex-1 overflow-y-auto flex flex-col">
        <header class="h-16 border-b border-slate-800/80 bg-slate-900/40 backdrop-blur px-8 flex items-center justify-between">
            <h1 class="text-xs font-bold text-white uppercase tracking-wider" x-text="currentTab"></h1>
            <div class="flex items-center space-x-4">
                <div class="flex items-center space-x-2 text-xs font-semibold px-3 py-1.5 rounded-full bg-slate-800 border border-slate-700">
                    <span class="w-2 h-2 rounded-full" :class="systemInfo.xray_status === 'running' ? 'bg-emerald-400 shadow-lg shadow-emerald-400/50' : 'bg-rose-400'"></span>
                    <span class="text-slate-300">Xray-Core: <span x-text="systemInfo.xray_status" class="uppercase"></span></span>
                </div>
            </div>
        </header>

        <div class="p-8 space-y-6">
            <div x-cloak x-show="toast.show" x-transition class="fixed bottom-6 right-6 z-50 px-4 py-3 rounded-xl shadow-xl flex items-center space-x-3 border"
                :class="toast.type === 'success' ? 'bg-emerald-950/90 text-emerald-300 border-emerald-800' : 'bg-rose-950/90 text-rose-300 border-rose-800'">
                <i :class="toast.type === 'success' ? 'ph ph-check-circle text-xl' : 'ph ph-x-circle text-xl'"></i>
                <span class="text-sm font-medium" x-text="toast.message"></span>
            </div>

            <!-- TAB 1: OVERVIEW -->
            <section x-show="currentTab === 'overview'" class="space-y-6">
                <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                    <div class="p-6 rounded-2xl bg-slate-900/60 border border-slate-800/80">
                        <div class="flex items-center justify-between text-slate-400 mb-2">
                            <span class="text-xs font-semibold uppercase tracking-wider">CPU Utilization</span>
                            <i class="ph ph-cpu text-xl text-indigo-400"></i>
                        </div>
                        <div class="text-3xl font-extrabold text-white" x-text="`${systemInfo.cpu}%`"></div>
                        <div class="w-full bg-slate-800 rounded-full h-1.5 mt-4">
                            <div class="bg-indigo-500 h-1.5 rounded-full" :style="`width: ${systemInfo.cpu}%`"></div>
                        </div>
                    </div>

                    <div class="p-6 rounded-2xl bg-slate-900/60 border border-slate-800/80">
                        <div class="flex items-center justify-between text-slate-400 mb-2">
                            <span class="text-xs font-semibold uppercase tracking-wider">RAM Consumption</span>
                            <i class="ph ph-hard-drive text-xl text-indigo-400"></i>
                        </div>
                        <div class="text-3xl font-extrabold text-white" x-text="`${systemInfo.ram}%`"></div>
                        <div class="w-full bg-slate-800 rounded-full h-1.5 mt-4">
                            <div class="bg-indigo-500 h-1.5 rounded-full" :style="`width: ${systemInfo.ram}%`"></div>
                        </div>
                    </div>

                    <div class="p-6 rounded-2xl bg-slate-900/60 border border-slate-800/80">
                        <div class="flex items-center justify-between text-slate-400 mb-2">
                            <span class="text-xs font-semibold uppercase tracking-wider">Storage Used</span>
                            <i class="ph ph-database text-xl text-indigo-400"></i>
                        </div>
                        <div class="text-3xl font-extrabold text-white" x-text="`${systemInfo.disk}%`"></div>
                        <div class="w-full bg-slate-800 rounded-full h-1.5 mt-4">
                            <div class="bg-indigo-500 h-1.5 rounded-full" :style="`width: ${systemInfo.disk}%`"></div>
                        </div>
                    </div>
                </div>
            </section>

            <!-- TAB 2: INBOUNDS -->
            <section x-show="currentTab === 'inbounds'" class="space-y-4">
                <div class="flex justify-between items-center">
                    <h3 class="text-base font-bold text-white">Active Inbounds</h3>
                    <button @click="modalInbound = true; generateRealityKeys();" class="px-4 py-2 bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl text-xs font-bold transition flex items-center space-x-1.5">
                        <i class="ph ph-plus font-bold"></i>
                        <span>Create Inbound</span>
                    </button>
                </div>

                <div class="bg-slate-900/60 border border-slate-800/80 rounded-2xl overflow-hidden">
                    <table class="w-full text-left text-sm text-slate-300">
                        <thead class="bg-slate-800/50 text-xs uppercase text-slate-400 font-semibold border-b border-slate-800">
                            <tr>
                                <th class="p-4">Tag</th>
                                <th class="p-4">Protocol</th>
                                <th class="p-4">Port</th>
                                <th class="p-4">Transport</th>
                                <th class="p-4">Clients</th>
                                <th class="p-4 text-right">Actions</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-slate-800/60">
                            <template x-for="ib in inbounds" :key="ib.id">
                                <tr class="hover:bg-slate-800/30 transition">
                                    <td class="p-4 font-semibold text-white" x-text="ib.tag"></td>
                                    <td class="p-4"><span class="px-2.5 py-1 rounded-md text-xs font-bold uppercase bg-indigo-950 text-indigo-400 border border-indigo-800/40" x-text="ib.protocol"></span></td>
                                    <td class="p-4 text-slate-300" x-text="ib.port"></td>
                                    <td class="p-4 text-slate-400" x-text="`${ib.stream.network} (${ib.stream.security})`"></td>
                                    <td class="p-4 text-slate-400" x-text="ib.client_count"></td>
                                    <td class="p-4 text-right">
                                        <button @click="deleteInbound(ib.id)" class="text-rose-400 hover:text-rose-300 p-2"><i class="ph ph-trash text-lg"></i></button>
                                    </td>
                                </tr>
                            </template>
                        </tbody>
                    </table>
                </div>
            </section>

            <!-- TAB 3: CLIENTS -->
            <section x-show="currentTab === 'clients'" class="space-y-4">
                <div class="flex justify-between items-center">
                    <h3 class="text-base font-bold text-white">Xray Proxy Clients</h3>
                    <button @click="modalClient = true" class="px-4 py-2 bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl text-xs font-bold transition flex items-center space-x-1.5">
                        <i class="ph ph-user-plus font-bold"></i>
                        <span>Add Client</span>
                    </button>
                </div>

                <div class="bg-slate-900/60 border border-slate-800/80 rounded-2xl overflow-hidden">
                    <table class="w-full text-left text-sm text-slate-300">
                        <thead class="bg-slate-800/50 text-xs uppercase text-slate-400 font-semibold border-b border-slate-800">
                            <tr>
                                <th class="p-4">Email</th>
                                <th class="p-4">Inbound ID</th>
                                <th class="p-4">UUID</th>
                                <th class="p-4">Status</th>
                                <th class="p-4 text-right">Actions</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-slate-800/60">
                            <template x-for="cl in clients" :key="cl.id">
                                <tr class="hover:bg-slate-800/30 transition">
                                    <td class="p-4 font-semibold text-white" x-text="cl.email"></td>
                                    <td class="p-4 text-slate-400" x-text="cl.inbound_id"></td>
                                    <td class="p-4 text-xs font-mono text-slate-400" x-text="cl.uuid.substring(0, 18) + '...'"></td>
                                    <td class="p-4"><span class="px-2 py-0.5 text-xs rounded bg-emerald-950 text-emerald-400 border border-emerald-800/40">Active</span></td>
                                    <td class="p-4 text-right space-x-2">
                                        <button @click="showShare(cl.email, cl.share_link)" class="text-indigo-400 hover:text-indigo-300 p-1.5"><i class="ph ph-qr-code text-lg"></i></button>
                                        <button @click="copyToClipboard(cl.share_link)" class="text-slate-400 hover:text-slate-200 p-1.5"><i class="ph ph-copy text-lg"></i></button>
                                        <button @click="deleteClient(cl.id)" class="text-rose-400 hover:text-rose-300 p-1.5"><i class="ph ph-trash text-lg"></i></button>
                                    </td>
                                </tr>
                            </template>
                        </tbody>
                    </table>
                </div>
            </section>

            <!-- TAB 4: SSH TUNNELS -->
            <section x-show="currentTab === 'ssh'" class="space-y-4">
                <div class="flex justify-between items-center">
                    <h3 class="text-base font-bold text-white">Native SSH Users (Tunnel Isolated)</h3>
                    <button @click="modalSSH = true" class="px-4 py-2 bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl text-xs font-bold transition flex items-center space-x-1.5">
                        <i class="ph ph-plus font-bold"></i>
                        <span>Provision SSH User</span>
                    </button>
                </div>

                <div class="bg-slate-900/60 border border-slate-800/80 rounded-2xl overflow-hidden">
                    <table class="w-full text-left text-sm text-slate-300">
                        <thead class="bg-slate-800/50 text-xs uppercase text-slate-400 font-semibold border-b border-slate-800">
                            <tr>
                                <th class="p-4">Username</th>
                                <th class="p-4">Max Connections</th>
                                <th class="p-4">Shell Status</th>
                                <th class="p-4">Created Date</th>
                                <th class="p-4 text-right">Actions</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-slate-800/60">
                            <template x-for="u in sshUsers" :key="u.id">
                                <tr class="hover:bg-slate-800/30 transition">
                                    <td class="p-4 font-semibold text-white font-mono" x-text="u.username"></td>
                                    <td class="p-4 text-slate-400" x-text="u.max_connections"></td>
                                    <td class="p-4"><span class="px-2 py-0.5 text-xs rounded bg-slate-800 text-indigo-300 border border-slate-700">mehboobxt-tunnel-shell</span></td>
                                    <td class="p-4 text-slate-400 text-xs" x-text="new Date(u.created_at).toLocaleDateString()"></td>
                                    <td class="p-4 text-right">
                                        <button @click="deleteSSHUser(u.id)" class="text-rose-400 hover:text-rose-300 p-2"><i class="ph ph-trash text-lg"></i></button>
                                    </td>
                                </tr>
                            </template>
                        </tbody>
                    </table>
                </div>
            </section>
        </div>
    </main>

    <!-- MODAL: ADD INBOUND -->
    <div x-cloak x-show="modalInbound" class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm">
        <div class="bg-slate-900 border border-slate-800 rounded-2xl p-6 w-full max-w-lg space-y-4">
            <h3 class="text-lg font-bold text-white">Create New Inbound</h3>
            <div class="space-y-3 text-sm">
                <div>
                    <label class="block text-xs uppercase text-slate-400 font-semibold mb-1">Tag</label>
                    <input type="text" x-model="newInbound.tag" class="w-full bg-slate-800 border border-slate-700 rounded-xl p-2.5 text-white" placeholder="vless-reality-in">
                </div>
                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <label class="block text-xs uppercase text-slate-400 font-semibold mb-1">Protocol</label>
                        <select x-model="newInbound.protocol" class="w-full bg-slate-800 border border-slate-700 rounded-xl p-2.5 text-white">
                            <option value="vless">VLESS</option>
                            <option value="vmess">VMess</option>
                            <option value="trojan">Trojan</option>
                        </select>
                    </div>
                    <div>
                        <label class="block text-xs uppercase text-slate-400 font-semibold mb-1">Port</label>
                        <input type="number" x-model.number="newInbound.port" class="w-full bg-slate-800 border border-slate-700 rounded-xl p-2.5 text-white">
                    </div>
                </div>
                <div>
                    <label class="block text-xs uppercase text-slate-400 font-semibold mb-1">Security</label>
                    <select x-model="newInbound.stream.security" class="w-full bg-slate-800 border border-slate-700 rounded-xl p-2.5 text-white">
                        <option value="reality">XTLS-Reality</option>
                        <option value="none">None</option>
                        <option value="tls">Standard TLS</option>
                    </select>
                </div>
            </div>
            <div class="flex justify-end space-x-3 pt-4 border-t border-slate-800">
                <button @click="modalInbound = false" class="px-4 py-2 rounded-xl text-slate-400 hover:bg-slate-800 text-sm">Cancel</button>
                <button @click="submitInbound()" class="px-4 py-2 bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl text-sm font-semibold">Save & Sync</button>
            </div>
        </div>
    </div>

    <!-- MODAL: ADD CLIENT -->
    <div x-cloak x-show="modalClient" class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm">
        <div class="bg-slate-900 border border-slate-800 rounded-2xl p-6 w-full max-w-md space-y-4">
            <h3 class="text-lg font-bold text-white">Add Xray Client</h3>
            <div class="space-y-3 text-sm">
                <div>
                    <label class="block text-xs uppercase text-slate-400 font-semibold mb-1">Select Inbound</label>
                    <select x-model.number="newClient.inbound_id" class="w-full bg-slate-800 border border-slate-700 rounded-xl p-2.5 text-white">
                        <template x-for="ib in inbounds" :key="ib.id">
                            <option :value="ib.id" x-text="`${ib.tag} (${ib.protocol} : ${ib.port})`"></option>
                        </template>
                    </select>
                </div>
                <div>
                    <label class="block text-xs uppercase text-slate-400 font-semibold mb-1">Client Email</label>
                    <input type="email" x-model="newClient.email" class="w-full bg-slate-800 border border-slate-700 rounded-xl p-2.5 text-white" placeholder="user@domain.com">
                </div>
                <div>
                    <label class="block text-xs uppercase text-slate-400 font-semibold mb-1">Flow</label>
                    <select x-model="newClient.flow" class="w-full bg-slate-800 border border-slate-700 rounded-xl p-2.5 text-white">
                        <option value="xtls-rprx-vision">xtls-rprx-vision (Reality)</option>
                        <option value="">None</option>
                    </select>
                </div>
            </div>
            <div class="flex justify-end space-x-3 pt-4 border-t border-slate-800">
                <button @click="modalClient = false" class="px-4 py-2 rounded-xl text-slate-400 hover:bg-slate-800 text-sm">Cancel</button>
                <button @click="submitClient()" class="px-4 py-2 bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl text-sm font-semibold">Save Client</button>
            </div>
        </div>
    </div>

    <!-- MODAL: ADD SSH USER -->
    <div x-cloak x-show="modalSSH" class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm">
        <div class="bg-slate-900 border border-slate-800 rounded-2xl p-6 w-full max-w-md space-y-4">
            <h3 class="text-lg font-bold text-white">Provision SSH Tunnel User</h3>
            <div class="space-y-3 text-sm">
                <div>
                    <label class="block text-xs uppercase text-slate-400 font-semibold mb-1">Username</label>
                    <input type="text" x-model="newSSH.username" class="w-full bg-slate-800 border border-slate-700 rounded-xl p-2.5 text-white" placeholder="tunnel_user">
                </div>
                <div>
                    <label class="block text-xs uppercase text-slate-400 font-semibold mb-1">Password</label>
                    <input type="password" x-model="newSSH.password" class="w-full bg-slate-800 border border-slate-700 rounded-xl p-2.5 text-white" placeholder="••••••••">
                </div>
                <div>
                    <label class="block text-xs uppercase text-slate-400 font-semibold mb-1">Max Connections</label>
                    <input type="number" x-model.number="newSSH.max_connections" class="w-full bg-slate-800 border border-slate-700 rounded-xl p-2.5 text-white">
                </div>
            </div>
            <div class="flex justify-end space-x-3 pt-4 border-t border-slate-800">
                <button @click="modalSSH = false" class="px-4 py-2 rounded-xl text-slate-400 hover:bg-slate-800 text-sm">Cancel</button>
                <button @click="submitSSH()" class="px-4 py-2 bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl text-sm font-semibold">Provision</button>
            </div>
        </div>
    </div>

    <!-- MODAL: SHARE QR -->
    <div x-cloak x-show="modalShare.show" class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm">
        <div class="bg-slate-900 border border-slate-800 rounded-2xl p-6 w-full max-w-sm space-y-4 text-center">
            <h3 class="text-lg font-bold text-white" x-text="modalShare.title"></h3>
            <div class="p-3 bg-white rounded-xl inline-block" id="qrcode"></div>
            <p class="text-xs text-slate-400 break-all font-mono" x-text="modalShare.link"></p>
            <div class="flex justify-center space-x-3 pt-2">
                <button @click="copyToClipboard(modalShare.link)" class="px-4 py-2 bg-indigo-600 text-white rounded-xl text-xs font-bold">Copy Link</button>
                <button @click="modalShare.show = false" class="px-4 py-2 bg-slate-800 text-slate-300 rounded-xl text-xs">Close</button>
            </div>
        </div>
    </div>
</div>
{% endblock %}
DASHBOARD_HTML_EOF

# ------------------------------------------------------------------------------
# 8. Main FastAPI Application with Modern TemplateResponse Syntax
# ------------------------------------------------------------------------------
log_info "Writing ${APP_DIR}/main.py..."
cat << 'MAIN_PY_EOF' > "${APP_DIR}/main.py"
import os
import psutil
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, RedirectResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from sqlalchemy import select

from app.core.config import settings
from app.core.security import get_password_hash, decode_access_token
from app.db.database import init_db, AsyncSessionLocal
from app.db.models import Admin
from app.services.xray_service import XrayService

# Routers (Phase 2 & Phase 3)
from app.api.auth import router as auth_router
from app.api.xray import router as xray_router
from app.api.inbounds import router as inbounds_router
from app.api.clients import router as clients_router
from app.api.ssh import router as ssh_router

TEMPLATES_DIR = "/opt/mehboobxt/app/templates"
STATIC_DIR = "/opt/mehboobxt/app/static"

templates = Jinja2Templates(directory=TEMPLATES_DIR)

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
    await init_db()
    await seed_initial_admin()
    async with AsyncSessionLocal() as session:
        try:
            await XrayService.sync_database_to_xray(session)
        except Exception as e:
            print(f"[WARN] Initial Xray sync deferred: {e}")
    yield

app = FastAPI(
    title="MehboobXT Panel",
    description="Enterprise VPS Management Panel (GUI + Xray-core + SSH Subsystem)",
    version="4.0.0",
    lifespan=lifespan
)

# Mount Static Assets
app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")

# Mount API Routers
app.include_router(auth_router)
app.include_router(xray_router)
app.include_router(inbounds_router)
app.include_router(clients_router)
app.include_router(ssh_router)

# Web UI Routes (Using updated Starlette/FastAPI TemplateResponse signature)
@app.get("/", response_class=HTMLResponse)
async def index_view(request: Request):
    token = request.cookies.get("access_token")
    if token and decode_access_token(token):
        return RedirectResponse(url="/dashboard", status_code=302)
    return RedirectResponse(url="/login", status_code=302)

@app.get("/login", response_class=HTMLResponse)
async def login_view(request: Request):
    token = request.cookies.get("access_token")
    if token and decode_access_token(token):
        return RedirectResponse(url="/dashboard", status_code=302)
    return templates.TemplateResponse(
        request=request,
        name="login.html"
    )

@app.get("/dashboard", response_class=HTMLResponse)
async def dashboard_view(request: Request):
    token = request.cookies.get("access_token")
    if not token or not decode_access_token(token):
        return RedirectResponse(url="/login", status_code=302)
    return templates.TemplateResponse(
        request=request,
        name="dashboard.html"
    )

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
MAIN_PY_EOF

# ------------------------------------------------------------------------------
# 9. Integrity Verification
# ------------------------------------------------------------------------------
log_info "Verifying file integrity..."
test -f "${APP_DIR}/templates/base.html"
test -f "${APP_DIR}/templates/login.html"
test -f "${APP_DIR}/templates/dashboard.html"
test -f "${APP_DIR}/static/css/custom.css"
test -f "${APP_DIR}/static/js/app.js"
test -f "${APP_DIR}/main.py"
log_success "All Phase 4 assets verified on disk."

log_info "Verifying Python compilation..."
"${VENV_PYTHON}" -m py_compile "${APP_DIR}/main.py"
log_success "Python compilation succeeded."

log_info "Testing Python dependencies in runtime environment..."
(cd "${PANEL_DIR}" && "${VENV_PYTHON}" -c "import psutil, jinja2; print('Phase 4 Python dependencies OK')")
log_success "Dependency imports verified."

# ------------------------------------------------------------------------------
# 10. Optional Repository Mirroring
# ------------------------------------------------------------------------------
if [[ -d "${REPO_DIR}/.git" ]]; then
    log_info "Synchronizing codebase with Git repository root (${REPO_DIR})..."
    mkdir -p "${REPO_DIR}/app"
    cp -a "${APP_DIR}/." "${REPO_DIR}/app/"
    cp -a "${PANEL_DIR}/deploy_phase4.sh" "${REPO_DIR}/deploy_phase4.sh"
    log_success "Repository mirror synchronized."
else
    log_warn "Git repository not detected at ${REPO_DIR}/.git; skipping mirror."
fi

# ------------------------------------------------------------------------------
# 11. Systemd Service Restart
# ------------------------------------------------------------------------------
log_info "Restarting mehboobxt.service..."
systemctl daemon-reload
systemctl restart mehboobxt.service

if systemctl is-active --quiet mehboobxt.service; then
    log_success "mehboobxt.service is active and healthy."
else
    log_fatal "mehboobxt.service failed to enter active state."
fi

log_success "Phase 4 Web UI deployed successfully!"
