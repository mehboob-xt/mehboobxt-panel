#!/usr/bin/env bash
#cat << 'EOF' > /opt/mehboobxt/fix_phase4_frontend.sh
# ==============================================================================
# MehboobXT VPS Panel - Phase 4 Frontend Repair Script
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

readonly PANEL_DIR="/opt/mehboobxt"
readonly APP_DIR="${PANEL_DIR}/app"
readonly REPO_DIR="/root/mehboobxt-panel"
readonly VENV_PYTHON="${PANEL_DIR}/venv/bin/python3"

echo "[INFO] Updating /opt/mehboobxt/app/static/js/app.js with deterministic Alpine lifecycle..."
cat << 'JS_EOF' > "${APP_DIR}/static/js/app.js"
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
            if (this.newInbound.stream.security === 'reality' && !this.newInbound.stream.reality_settings.private_key) {
                this.generateRealityKeys();
            }
        },

        async submitInbound() {
            this.loading = true;
            try {
                const payload = JSON.parse(JSON.stringify(this.newInbound));
                if (payload.stream.security !== 'reality') {
                    payload.stream.reality_settings = null;
                } else {
                    if (!payload.stream.reality_settings.private_key || !payload.stream.reality_settings.public_key) {
                        this.notify("Please generate or provide Reality keys", "error");
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

// Deterministic Registration Strategy:
// 1. Alpine lifecycle hook
document.addEventListener('alpine:init', () => {
    Alpine.data('panelApp', panelAppData);
});

// 2. Direct assignment if Alpine has already initialized
if (window.Alpine) {
    window.Alpine.data('panelApp', panelAppData);
}

// 3. Global function fallback (Alpine falls back to window.panelApp())
window.panelApp = panelAppData;
JS_EOF

echo "[INFO] Updating /opt/mehboobxt/app/templates/base.html with explicit app.js inclusion..."
cat << 'BASE_EOF' > "${APP_DIR}/templates/base.html"
<!DOCTYPE html>
<html lang="en" class="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{% block title %}MehboobXT Panel{% endblock %}</title>
    <!-- Tailwind CSS Play CDN -->
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
    <!-- Phosphor Icons -->
    <script src="https://unpkg.com/@phosphor-icons/web"></script>
    <!-- QRCode.js (Non-blocking fallback) -->
    <script src="https://cdn.jsdelivr.net/npm/qrcodejs@1.0.0/qrcode.min.js"></script>
    <!-- Custom Stylesheet -->
    <link rel="stylesheet" href="/static/css/custom.css">
    
    <!-- Core Application Component (Loaded BEFORE Alpine so stores are declared) -->
    <script src="/static/js/app.js"></script>
    
    <!-- Alpine.js Core (deferred execution) -->
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.13.5/dist/cdn.min.js"></script>
</head>
<body class="bg-slate-950 text-slate-100 min-h-screen antialiased flex flex-col font-sans">
    {% block content %}{% endblock %}
</body>
</html>
BASE_EOF

echo "[INFO] Updating /opt/mehboobxt/app/templates/dashboard.html with mobile drawer & responsive layout..."
cat << 'DASH_EOF' > "${APP_DIR}/templates/dashboard.html"
{% extends "base.html" %}
{% block title %}Dashboard - MehboobXT Panel{% endblock %}
{% block content %}
<div x-data="panelApp" class="flex flex-col md:flex-row h-screen overflow-hidden bg-slate-950">

    <!-- Mobile Drawer Overlay -->
    <div x-cloak x-show="mobileMenuOpen" @click="mobileMenuOpen = false" 
         class="fixed inset-0 z-30 bg-black/60 backdrop-blur-sm md:hidden"></div>

    <!-- Responsive Sidebar (Drawer on mobile, fixed column on desktop) -->
    <aside :class="mobileMenuOpen ? 'translate-x-0' : '-translate-x-full md:translate-x-0'"
           class="fixed inset-y-0 left-0 z-40 w-64 bg-slate-900 border-r border-slate-800 flex flex-col justify-between p-4 transition-transform duration-200 ease-in-out md:static md:translate-x-0">
        <div>
            <div class="flex items-center justify-between px-2 py-4 mb-4">
                <div class="flex items-center space-x-3">
                    <div class="w-10 h-10 rounded-xl bg-indigo-600/20 text-indigo-400 flex items-center justify-center border border-indigo-500/30">
                        <i class="ph-bold ph-shield-check text-2xl"></i>
                    </div>
                    <div>
                        <h2 class="font-bold text-base text-white">MehboobXT</h2>
                        <span class="text-xs text-indigo-400 font-medium">Enterprise v4.0</span>
                    </div>
                </div>
                <button @click="mobileMenuOpen = false" class="md:hidden text-slate-400 hover:text-white p-1">
                    <i class="ph ph-x text-xl"></i>
                </button>
            </div>

            <nav class="space-y-1.5">
                <button @click="currentTab = 'overview'; mobileMenuOpen = false" 
                        :class="currentTab === 'overview' ? 'bg-indigo-600/20 text-indigo-400 border border-indigo-500/30' : 'text-slate-400 hover:bg-slate-800/60 hover:text-slate-200'" 
                        class="w-full flex items-center space-x-3 px-3.5 py-2.5 rounded-xl font-medium text-sm transition-all">
                    <i class="ph ph-squares-four text-lg"></i>
                    <span>Overview</span>
                </button>
                <button @click="currentTab = 'inbounds'; mobileMenuOpen = false" 
                        :class="currentTab === 'inbounds' ? 'bg-indigo-600/20 text-indigo-400 border border-indigo-500/30' : 'text-slate-400 hover:bg-slate-800/60 hover:text-slate-200'" 
                        class="w-full flex items-center space-x-3 px-3.5 py-2.5 rounded-xl font-medium text-sm transition-all">
                    <i class="ph ph-arrows-in-cardinal text-lg"></i>
                    <span>Inbounds</span>
                </button>
                <button @click="currentTab = 'clients'; mobileMenuOpen = false" 
                        :class="currentTab === 'clients' ? 'bg-indigo-600/20 text-indigo-400 border border-indigo-500/30' : 'text-slate-400 hover:bg-slate-800/60 hover:text-slate-200'" 
                        class="w-full flex items-center space-x-3 px-3.5 py-2.5 rounded-xl font-medium text-sm transition-all">
                    <i class="ph ph-users text-lg"></i>
                    <span>Xray Clients</span>
                </button>
                <button @click="currentTab = 'ssh'; mobileMenuOpen = false" 
                        :class="currentTab === 'ssh' ? 'bg-indigo-600/20 text-indigo-400 border border-indigo-500/30' : 'text-slate-400 hover:bg-slate-800/60 hover:text-slate-200'" 
                        class="w-full flex items-center space-x-3 px-3.5 py-2.5 rounded-xl font-medium text-sm transition-all">
                    <i class="ph ph-terminal-window text-lg"></i>
                    <span>SSH Tunnels</span>
                </button>
            </nav>
        </div>

        <div class="border-t border-slate-800 pt-4">
            <button @click="logout()" class="w-full flex items-center space-x-3 px-3.5 py-2.5 text-rose-400 hover:bg-rose-500/10 rounded-xl font-medium text-sm transition-all">
                <i class="ph ph-sign-out text-lg"></i>
                <span>Sign Out</span>
            </button>
        </div>
    </aside>

    <!-- Main Workspace Canvas -->
    <main class="flex-1 overflow-y-auto flex flex-col min-w-0">
        <!-- Topbar -->
        <header class="h-16 border-b border-slate-800 bg-slate-900/40 backdrop-blur px-4 md:px-8 flex items-center justify-between shrink-0">
            <div class="flex items-center space-x-3">
                <button @click="mobileMenuOpen = true" class="md:hidden text-slate-300 hover:text-white p-1 rounded-lg border border-slate-700">
                    <i class="ph ph-list text-2xl"></i>
                </button>
                <h1 class="text-sm md:text-base font-bold text-white uppercase tracking-wider" x-text="currentTab"></h1>
            </div>
            <div class="flex items-center space-x-3">
                <div class="flex items-center space-x-2 text-xs font-semibold px-3 py-1.5 rounded-full bg-slate-800 border border-slate-700">
                    <span class="w-2 h-2 rounded-full" :class="systemInfo.xray_status === 'running' ? 'bg-emerald-400 shadow-lg shadow-emerald-400/50' : 'bg-rose-400'"></span>
                    <span class="text-slate-300">Xray-Core: <span x-text="systemInfo.xray_status" class="uppercase"></span></span>
                </div>
            </div>
        </header>

        <!-- Main Workspace -->
        <div class="p-4 md:p-8 space-y-6 flex-1">
            <!-- Toast Notification -->
            <div x-cloak x-show="toast.show" x-transition class="fixed bottom-6 right-6 z-50 px-4 py-3 rounded-xl shadow-xl flex items-center space-x-3 border"
                :class="toast.type === 'success' ? 'bg-emerald-950/90 text-emerald-300 border-emerald-800' : 'bg-rose-950/90 text-rose-300 border-rose-800'">
                <i :class="toast.type === 'success' ? 'ph ph-check-circle text-xl' : 'ph ph-x-circle text-xl'"></i>
                <span class="text-sm font-medium" x-text="toast.message"></span>
            </div>

            <!-- TAB 1: OVERVIEW -->
            <section x-show="currentTab === 'overview'" class="space-y-6">
                <div class="grid grid-cols-1 md:grid-cols-3 gap-4 md:gap-6">
                    <div class="p-6 rounded-2xl bg-slate-900/60 border border-slate-800">
                        <div class="flex items-center justify-between text-slate-400 mb-2">
                            <span class="text-xs font-semibold uppercase tracking-wider">CPU Utilization</span>
                            <i class="ph ph-cpu text-xl text-indigo-400"></i>
                        </div>
                        <div class="text-3xl font-extrabold text-white" x-text="`${systemInfo.cpu}%`"></div>
                        <div class="w-full bg-slate-800 rounded-full h-1.5 mt-4">
                            <div class="bg-indigo-500 h-1.5 rounded-full transition-all duration-300" :style="`width: ${systemInfo.cpu}%`"></div>
                        </div>
                    </div>

                    <div class="p-6 rounded-2xl bg-slate-900/60 border border-slate-800">
                        <div class="flex items-center justify-between text-slate-400 mb-2">
                            <span class="text-xs font-semibold uppercase tracking-wider">RAM Consumption</span>
                            <i class="ph ph-hard-drive text-xl text-indigo-400"></i>
                        </div>
                        <div class="text-3xl font-extrabold text-white" x-text="`${systemInfo.ram}%`"></div>
                        <div class="w-full bg-slate-800 rounded-full h-1.5 mt-4">
                            <div class="bg-indigo-500 h-1.5 rounded-full transition-all duration-300" :style="`width: ${systemInfo.ram}%`"></div>
                        </div>
                    </div>

                    <div class="p-6 rounded-2xl bg-slate-900/60 border border-slate-800">
                        <div class="flex items-center justify-between text-slate-400 mb-2">
                            <span class="text-xs font-semibold uppercase tracking-wider">Disk Storage Used</span>
                            <i class="ph ph-database text-xl text-indigo-400"></i>
                        </div>
                        <div class="text-3xl font-extrabold text-white" x-text="`${systemInfo.disk}%`"></div>
                        <div class="w-full bg-slate-800 rounded-full h-1.5 mt-4">
                            <div class="bg-indigo-500 h-1.5 rounded-full transition-all duration-300" :style="`width: ${systemInfo.disk}%`"></div>
                        </div>
                    </div>
                </div>
            </section>

            <!-- TAB 2: INBOUNDS -->
            <section x-show="currentTab === 'inbounds'" class="space-y-4">
                <div class="flex justify-between items-center">
                    <h3 class="text-base font-bold text-white">Active Inbounds</h3>
                    <button @click="openInboundModal()" class="px-4 py-2 bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl text-xs font-bold transition flex items-center space-x-1.5">
                        <i class="ph ph-plus font-bold"></i>
                        <span>Create Inbound</span>
                    </button>
                </div>

                <div class="bg-slate-900/60 border border-slate-800 rounded-2xl overflow-x-auto">
                    <table class="w-full text-left text-sm text-slate-300 min-w-[500px]">
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

                <div class="bg-slate-900/60 border border-slate-800 rounded-2xl overflow-x-auto">
                    <table class="w-full text-left text-sm text-slate-300 min-w-[600px]">
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

                <div class="bg-slate-900/60 border border-slate-800 rounded-2xl overflow-x-auto">
                    <table class="w-full text-left text-sm text-slate-300 min-w-[500px]">
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
        <div class="bg-slate-900 border border-slate-800 rounded-2xl p-6 w-full max-w-lg space-y-4 max-h-[90vh] overflow-y-auto">
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
                <div x-show="newInbound.stream.security === 'reality'" class="space-y-3 border-t border-slate-800 pt-3">
                    <div class="flex justify-between items-center">
                        <span class="text-xs font-bold text-indigo-400 uppercase">Reality Configuration</span>
                        <button type="button" @click="generateRealityKeys()" class="text-xs text-indigo-400 hover:text-indigo-300 underline">Generate Keys</button>
                    </div>
                    <div>
                        <label class="block text-xs text-slate-400 mb-1">Private Key</label>
                        <input type="text" x-model="newInbound.stream.reality_settings.private_key" class="w-full bg-slate-800 border border-slate-700 rounded-xl p-2 text-xs font-mono text-white">
                    </div>
                    <div>
                        <label class="block text-xs text-slate-400 mb-1">Public Key</label>
                        <input type="text" x-model="newInbound.stream.reality_settings.public_key" class="w-full bg-slate-800 border border-slate-700 rounded-xl p-2 text-xs font-mono text-white">
                    </div>
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
DASH_EOF

# Mirror to Git Working Tree
if [[ -d "${REPO_DIR}/.git" ]]; then
    echo "[INFO] Mirroring repaired templates and JS to ${REPO_DIR}..."
    mkdir -p "${REPO_DIR}/app/templates" "${REPO_DIR}/app/static/js"
    cp -a "${APP_DIR}/templates/." "${REPO_DIR}/app/templates/"
    cp -a "${APP_DIR}/static/js/." "${REPO_DIR}/app/static/js/"
fi

# Reload systemd and restart service
systemctl daemon-reload
systemctl restart mehboobxt.service

echo "[OK] Frontend repair deployed successfully."
EOF

chmod +x /opt/mehboobxt/fix_phase4_frontend.sh
/opt/mehboobxt/fix_phase4_frontend.sh
