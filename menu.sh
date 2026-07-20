#!/bin/bash
source modules/ssh.sh
clear

GREEN="\033[0;32m"
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
RESET="\033[0m"

while true
do

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
echo -e "${GREEN}06.${RESET} Account Generator"
echo -e "${GREEN}07.${RESET} Backup System"
echo -e "${GREEN}08.${RESET} VPS Information"
echo -e "${GREEN}09.${RESET} Panel Update"
echo -e "${GREEN}10.${RESET} Exit"

echo ""
read -p " Select Option : " option


case $option in

1)
ssh_menu
;;

2)
echo "VLESS Manager Loading..."
sleep 2
;;

3)
echo "VMess Manager Loading..."
sleep 2
;;

4)
echo "Trojan Manager Loading..."
sleep 2
;;

5)
source core/expiry.sh
expiry_menu
;;

6)
echo "Account Generator Loading..."
sleep 2
;;

7)
echo "Backup System Loading..."
sleep 2
;;

8)
echo "Checking VPS..."
uname -a
sleep 3
;;

9)
echo "Updating Panel..."
sleep 2
;;

10)
echo "Exit MehboobXT Panel"
exit
;;

*)
echo "Invalid Option"
sleep 2
;;

esac

done
