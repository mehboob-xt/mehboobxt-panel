<p align="center">
  <img src="https://raw.githubusercontent.com/mehboob-xt/mehboobxt-panel/main/logo.png" alt="MehboobXT Panel" width="280">
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/mehboob-xt/mehboobxt-panel/main/logo.png" alt="MehboobXT Panel" width="280">
</p>

<p align="center">
  <a href="#"><img src="https://img.shields.io/badge/English-blue?style=flat-square"></a>
  <a href="#"><img src="https://img.shields.io/badge/اردو-green?style=flat-square"></a>
  <a href="#"><img src="https://img.shields.io/badge/فارسی-red?style=flat-square"></a>
  <a href="#"><img src="https://img.shields.io/badge/中文-orange?style=flat-square"></a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/release-v1.0.0-blue?style=flat-square" alt="release">
  <img src="https://img.shields.io/badge/build-passing-brightgreen?style=flat-square" alt="build">
  <img src="https://img.shields.io/badge/Go-1.22+-00ADD8?style=flat-square&logo=go" alt="Go">
  <img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="license">
  <img src="https://img.shields.io/badge/platform-Linux-orange?style=flat-square" alt="platform">
</p>

**MehboobXT Panel** is an advanced, premium web control panel for managing Xray-core servers.  
It provides a clean, modern, and powerful interface for deploying, configuring, and monitoring a wide range of proxy and VPN protocols — from a single VPS to multi-node deployments.

Built as a highly enhanced and feature-rich panel, MehboobXT adds broader protocol support, improved stability, advanced client management, custom config generators, and many premium quality-of-life features.

> [!IMPORTANT]
> This project is intended for **personal use only**. Please do not use it for illegal purposes or in a production environment.

---

### ✨ Features

- **Multi-protocol inbounds** — VLESS, VMess, Trojan, Shadowsocks, WireGuard, Hysteria2, SSH, HTTP, SOCKS (Mixed), and more.
- **Modern transports & security** — TCP, WebSocket, gRPC, HTTPUpgrade, XHTTP, secured with TLS, XTLS, and REALITY.
- **Fallbacks** — Serve multiple protocols on a single port (e.g. VLESS + Trojan on 443).
- **Per-client management** — Traffic quotas, expiry dates, IP limits, live online status, one-click share links, QR codes, and subscriptions.
- **Traffic statistics** — Per inbound, per client, and per outbound with reset controls.
- **Multi-node support** — Manage and scale across multiple servers from a single panel.
- **Outbound & routing** — WARP, custom routing rules, load balancers, and outbound proxy chaining.
- **Built-in subscription server** with multiple output formats and custom page templates.
- **Telegram bot** for remote monitoring and management.
- **RESTful API** with documentation.
- **Flexible storage** — SQLite (default) or PostgreSQL.
- **Auto SSL** with Let's Encrypt.
- **Fail2Ban integration** for enforcing per-client IP limits.
- **Premium Tools** (Coming Soon)
  - Advanced Config Generator (HTTP Custom + Dark Tunnel + FreeBasics)
  - Reseller System with Balance & Permissions
  - Custom Branding
  - Multi-Admin Roles

---

### 📸 Screenshots

> Screenshots will be added soon.

---

### 🚀 Quick Start

```bash
bash <(curl -Ls https://raw.githubusercontent.com/mehboob-xt/mehboobxt-panel/main/install.sh)
