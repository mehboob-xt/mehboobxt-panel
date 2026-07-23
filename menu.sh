#!/bin/bash

BASE_DIR="/opt/mehboobxt"
MODULE_DIR="$BASE_DIR/modules"

source "$BASE_DIR/core/core.sh"
source "$MODULE_DIR/ssh.sh"
source "$MODULE_DIR/vless.sh"
while true
do

header

echo "1. SSH Manager"
echo "2. VLESS Manager"
echo "3. System Info"
echo "4. Backup"
echo "5. Update Panel"
echo "6. Exit"

echo ""

read -p "Select Option: " option


case $option in

1)

ssh_menu

;;

2)

vless_menu

;;

3)

echo ""
echo "🖥 System Information"
echo "---------------------"

hostname
uptime
df -h /

sleep 3

;;

4)

echo ""
echo "📦 Backup System"

mkdir -p /etc/mehboobxt/backups

tar -czf /etc/mehboobxt/backups/panel_backup_$(date +%Y-%m-%d).tar.gz /etc/mehboobxt

echo "✅ Backup Created"

sleep 3

;;

5)

if [ -f "$MODULE_DIR/update.sh" ]
then

source "$MODULE_DIR/update.sh"
update_panel

else

echo "❌ Update Module Missing"

sleep 2

fi

;;

6)

echo "Bye 👋"
exit

;;

*)

echo "Invalid Option"
sleep 2

;;

esac

done
