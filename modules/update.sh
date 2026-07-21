#!/bin/bash

update_panel() {

clear

echo "================================="
echo "🚀 MehboobXT Panel Updater"
echo "================================="

echo "📦 Creating backup..."
mkdir -p /etc/mehboobxt/backups
tar -czf /etc/mehboobxt/backups/panel-$(date +%F-%H%M).tar.gz /opt/mehboobxt >/dev/null 2>&1

echo "📥 Downloading latest version..."

cd /tmp || exit
rm -rf mehboobxt-update

git clone https://github.com/mehboob-xt/mehboobxt-panel.git mehboobxt-update || {
    echo "❌ Update failed."
    read -p "Press Enter..."
    return
}

echo "📂 Updating files..."

cp -rf mehboobxt-update/core/* /opt/mehboobxt/core/
cp -rf mehboobxt-update/modules/* /opt/mehboobxt/modules/
cp -f mehboobxt-update/menu.sh /opt/mehboobxt/
cp -f mehboobxt/install.sh /opt/mehboobxt/

chmod +x /opt/mehboobxt/core/*.sh
chmod +x /opt/mehboobxt/modules/*.sh
chmod +x /opt/mehboobxt/menu.sh

rm -rf /tmp/mehboobxt-update

echo ""
echo "✅ Panel Updated Successfully!"
echo ""

read -p "Press Enter to continue..."
}
