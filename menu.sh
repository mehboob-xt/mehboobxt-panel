#!/bin/bash

source "$BASE_DIR/core/core.sh"
# =====================================
# MehboobXT Panel Main Menu
# Version: 1.0.0
# =====================================

BASE_DIR="/opt/mehboobxt"
MODULE_DIR="$BASE_DIR/modules"

while true
do

header

echo "1. VLESS Manager"
echo "2. System Info"
echo "3. Backup"
echo "4. Update Panel"
echo "5. Exit"

echo ""

read -p "Select Option: " option


case $option in

1)

if [ -f "$MODULE_DIR/vless.sh" ]
then

bash "$MODULE_DIR/vless.sh"

else

echo "❌ VLESS Module Missing"

sleep 2

fi

;;

2)

echo ""
echo "🖥 System Information"
echo "---------------------"

hostname
uptime
df -h /

sleep 3

;;

3)

echo ""
echo "📦 Backup System"

mkdir -p /etc/mehboobxt/backups

tar -czf /etc/mehboobxt/backups/panel_backup_$(date +%Y-%m-%d).tar.gz /etc/mehboobxt

echo "✅ Backup Created"

sleep 3

;;

4)

if [ -f "$MODULE_DIR/update.sh" ]
then

source "$MODULE_DIR/update.sh"
update_panel

else

echo "❌ Update Module Missing"

sleep 2

fi

;;

5)

echo "Bye 👋"
exit

;;

*)

echo "Invalid Option"
sleep 2

;;

esac

done
