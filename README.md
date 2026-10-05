# Mehboob-XT VPS Panel

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Platform: Linux](https://img.shields.io/badge/Platform-Debian%20%7C%20Ubuntu-orange.svg)](https://www.debian.org/)
[![Engine: Xray-core](https://img.shields.io/badge/Engine-Xray--core-red.svg)](https://github.com/XTLS/Xray-core)
[![Backend: FastAPI](https://img.shields.io/badge/Backend-FastAPI%20(Python%203)-green.svg)](https://fastapi.tiangolo.com/)

**Mehboob-XT Panel** is an enterprise-grade, high-performance VPS management control system designed for proxy protocol orchestration, SSH tunnel multiplexing, and client bandwidth accounting. Inspired by the flexibility of **3x-ui** and the user-centric architecture of **Marz-X**, Mehboob-XT delivers unified control over Xray-core, native SSH subsystems, and modern tunneling transports.

---

## ⚡ Key Highlights

### 1. Multi-Protocol Inbound Management
* **Xray-Core Native:** VLESS, VMess, Trojan, Shadowsocks (2022-blake3 / AEAD), SOCKS5, and HTTP proxy.
* **Modern Transports:** TCP, WebSocket (WS), gRPC, HTTPUpgrade, and SplitHTTP.
* **Next-Gen Security:** XTLS-Vision, REALITY (eliminating the need for custom domain certificates via TLS 1.3 SNI spoofing), and standard TLS/mTLS.
* **Extended Protocols:** WireGuard endpoint bridging and Hysteria2 UDP acceleration.

### 2. Native SSH Tunnel Management
* Dedicated Linux user provisioning without full shell access (`/usr/sbin/nologin`).
* Connection concurrency limit enforcement per user.
* Expiration dates, data limits, and multi-port listening (Direct OpenSSH / Dropbear integration).

### 3. High-Performance Web Dashboard & CLI
* **Web UI:** Responsive single-page interface powered by a lightweight FastAPI backend and asynchronous SQLite persistence.
* **CLI Engine (`menu.sh`):** Terminal UI with zero external dependencies for headless system administration, port resetting, core updates, and node diagnostics.

### 4. Hardened Security by Default
* Automated UFW/NFTables rule adjustments on inbound mutation.
* Automated Let's Encrypt SSL/TLS issuance and renewal (Standalone + DNS challenge).
* In-memory brute-force rate-limiting and dynamic Fail2ban rules for panel authentication.

---

## 🖥️ System Compatibility

| Operating System | Versions Supported | Status |
| :--- | :--- | :--- |
| **Ubuntu** | 20.04 LTS, 22.04 LTS, 24.04 LTS | **Fully Supported** |
| **Debian** | 11 (Bullseye), 12 (Bookworm) | **Fully Supported** |
| **Architecture** | `x86_64` (amd64), `aarch64` (arm64) | **Supported** |

---

## 🚀 Quick Installation

Run the master bootstrap command as `root`:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/mehboob-xt/panel/main/install.sh)"
