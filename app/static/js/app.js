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
