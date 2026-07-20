#!/bin/bash

vless_menu(){

while true
do

clear

echo "=========================="
echo "🔐 MehboobXT VLESS Manager"
echo "=========================="

echo "1. Check X-UI Status"
echo "2. Back"

echo ""

read -p "Select Option: " vlessopt

case $vlessopt in

1)

systemctl status x-ui --no-pager

sleep 3
;;

2)

break
;;

*)

echo "Invalid Option"
sleep 2
;;

esac

done

}
