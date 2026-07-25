#!/bin/bash

BASE_DIR="/opt/mehboobxt"
MODULE_DIR="$BASE_DIR/modules"

source "$BASE_DIR/core/core.sh"
source "$MODULE_DIR/ssh.sh"
source "$MODULE_DIR/vless.sh"
source "$MODULE_DIR/vmess.sh"
source "$MODULE_DIR/trojan.sh"
source "$MODULE_DIR/referral.sh"
source "$MODULE_DIR/expiry.sh"

while true
do

header

echo "1. SSH Manager"
echo "2. VLESS Manager"
echo "3. VMess Manager"
echo "4. Trojan Manager"
echo "5. Expiry Manager"
echo "6. Referral Manager"
echo "7. System Info"
echo "8. Backup"
echo "9. Update Panel"
echo "10. Exit"

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
vmess_menu
;;

4)
trojan_menu
;;

5)
expiry_menu
;;

6)
referral_menu
;;

7)

echo ""
echo "🖥 System Information"
echo "---------------------"

hostname
uptime
df -h /

sleep 3

;;

8)

echo ""
echo "📦 Backup System"

mkdir -p /etc/mehboobxt/backups

tar -czf /etc/mehboobxt/backups/panel_backup_$(date +%Y-%m-%d).tar.gz /etc/mehboobxt

echo "✅ Backup Created"

sleep 3

;;

9)

if [ -f "$MODULE_DIR/update.sh" ]
then

source "$MODULE_DIR/update.sh"
update_panel

else

echo "❌ Update Module Missing"

sleep 2

fi

;;

10)

echo "Bye 👋"
exit

;;

*)

echo "Invalid Option"
sleep 2

;;

esac

done
