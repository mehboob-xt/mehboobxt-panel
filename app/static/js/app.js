document.addEventListener('alpine:init', () => {
    Alpine.data('panelApp', () => ({
        currentTab: 'overview',
        systemInfo: { cpu: 0, ram: 0, disk: 0, xray_status: 'loading' },
        inbounds: [],
        clients: [],
        sshUsers: [],
        loading: false,
        toast: { show: false, message: '', type: 'success' },

        // Modals
        modalInbound: false,
        modalClient: false,
        modalSSH: false,
        modalShare: { show: false, link: '', title: '' },

        // Inbound Form
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

        // Client Form
        newClient: {
            inbound_id: '',
            email: '',
            uuid: '',
            flow: 'xtls-rprx-vision'
        },

        // SSH User Form
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
                console.error("Health fetch error", e);
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
