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
apt install -y ca-certificates

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

# Database Directory
mkdir -p /opt/mehboobxt/database

touch /opt/mehboobxt/database/accounts.db
touch /opt/mehboobxt/database/users.json
touch /opt/mehboobxt/database/expiry.db

# Download Panel Files
echo "📦 Downloading MehboobXT Panel files..."

cd /opt/mehboobxt
rm -rf temp

git clone --depth 1 https://github.com/mehboob-xt/mehboobxt-panel.git temp

if [ $? -ne 0 ]; then
    echo "❌ Failed to download panel files."
    exit 1
fi

if [ ! -f temp/menu.sh ]; then
    echo "❌ menu.sh not found."
    exit 1
fi

if [ ! -d temp/core ] || [ ! -d temp/modules ]; then
    echo "❌ Core files missing."
    exit 1
fi

cp temp/menu.sh .
mkdir -p /opt/mehboobxt/core
cp -rf temp/core/* /opt/mehboobxt/core/
mkdir -p /opt/mehboobxt/modules
cp -rf temp/modules/* /opt/mehboobxt/modules/

[ -d temp/config ] && cp -rf temp/config /opt/mehboobxt/
[ -f temp/version ] && cp temp/version /opt/mehboobxt/
echo "⚙️ Installing Core Files..."

chmod +x /opt/mehboobxt/core/*.sh
chmod +x /opt/mehboobxt/modules/*.sh

echo "✅ Core Installed"
echo "✅ Core System Installed"

rm -rf temp

chmod +x menu.sh
chmod +x core/*.sh
chmod +x modules/*.sh
[ -f core/core.sh ] && chmod +x core/core.sh

echo "✅ Panel files installed"
# Version File


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

VERSION="Unknown"

if [ -f /opt/mehboobxt/version ]; then
    VERSION=$(cat /opt/mehboobxt/version)
fi

echo " Version: $VERSION"
echo "======================================"
