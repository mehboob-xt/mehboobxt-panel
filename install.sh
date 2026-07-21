#!/bin/bash

# ==========================================
# MehboobXT Panel Installer
# Version: 1.0.0
# ==========================================

clear

echo "======================================"
echo " 🚀 MehboobXT Panel Installer"
echo " Version: 1.0.0"
echo "======================================"

# Root Check
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root"
    exit 1
fi

echo "✅ Root access confirmed"

# System Update
echo "📦 Updating system packages..."
apt update -y
apt upgrade -y

# Required Packages
echo "📦 Installing required packages..."
apt install -y curl wget git nano unzip jq

# Create Directory
echo "📁 Creating MehboobXT directories..."

echo "⚙️ Creating Panel Configuration..."

mkdir -p /etc/mehboobxt

cat > /etc/mehboobxt/panel.conf <<EOF
DOMAIN="tech.mehboobxt.ggff.net"
PORT="443"
WS_PATH="/vless"
EOF

echo "✅ Configuration Created"

mkdir -p /opt/mehboobxt
mkdir -p /opt/mehboobxt/core
mkdir -p /opt/mehboobxt/modules
mkdir -p /opt/mehboobxt/webpanel
# Download Panel Files

echo "📦 Downloading MehboobXT Panel files..."

cd /opt/mehboobxt

git clone https://github.com/mehboob-xt/mehboobxt-panel.git temp

cp temp/menu.sh .
cp temp/install.sh .
cp -r temp/core/* core/
cp -r temp/modules/* modules/
echo "⚙️ Installing Core Files..."

mkdir -p /opt/mehboobxt/core

cp -r core/* /opt/mehboobxt/core/

chmod +x /opt/mehboobxt/core/*.sh

echo "✅ Core Installed"

rm -rf temp

chmod +x menu.sh
chmod +x core/*.sh
chmod +x modules/*.sh

echo "✅ Panel files installed"
# Version File

echo "1.0.0" > /opt/mehboobxt/version
# Create Panel Command

echo "🔗 Creating mehboobxt command..."

cat > /usr/local/bin/mehboobxt << 'EOF'
#!/bin/bash
cd /opt/mehboobxt
bash menu.sh
EOF

chmod +x /usr/local/bin/mehboobxt

echo "✅ Command created: mehboobxt"
echo ""
echo "======================================"
echo " ✅ MehboobXT Panel Installed"
echo " Location: /opt/mehboobxt"
echo " Version: 1.0.0"
echo "======================================"
