#!/bin/bash

source core/functions.sh

load_module modules/ssh.sh
load_module modules/vless.sh
load_module modules/vmess.sh
load_module modules/trojan.sh
load_module modules/expiry.sh
load_module modules/referral.sh
load_module modules/account_generator.sh
load_module modules/backup.sh
load_module modules/vps_info.sh
load_module modules/update.sh

check_root

while true
do

panel_header

echo -e "${CYAN}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 🚀 MehboobXT Panel"
echo " Enterprise VPS Management"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${RESET}"

echo -e "${GREEN}01.${RESET} SSH Manager"
echo -e "${GREEN}02.${RESET} VLESS Manager"
echo -e "${GREEN}03.${RESET} VMess Manager"
echo -e "${GREEN}04.${RESET} Trojan Manager"
echo -e "${GREEN}05.${RESET} Expiry Manager"
echo -e "${GREEN}06.${RESET} Referral System"
echo -e "${GREEN}07.${RESET} Account Generator"
echo -e "${GREEN}08.${RESET} Backup System"
echo -e "${GREEN}09.${RESET} VPS Information"
echo -e "${GREEN}10.${RESET} Panel Update"
echo -e "${GREEN}11.${RESET} Exit"

echo ""
read -p " Select Option : " option


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
account_generator
;;

8)
backup_menu
;;

9)
vps_info
;;

10)
update_panel
;;

11)
echo "Exit MehboobXT Panel"
exit
;;

*)
echo "Invalid Option"
sleep 2
;;

esac

done
