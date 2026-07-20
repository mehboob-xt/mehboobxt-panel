#!/bin/bash

vless_menu(){

while true
do

clear

echo "=========================="
echo "🔐 MehboobXT VLESS Manager"
echo "=========================="

echo "1. Create VLESS Account"
echo "2. List VLESS Account"
echo "3. Delete VLESS Account"
echo "4. Back"

echo ""

read -p "Select Option: " vlessopt

case $vlessopt in

1)
echo "Creating VLESS Account..."
sleep 2
;;

2)
echo "Listing VLESS Account..."
sleep 2
;;

3)
echo "Deleting VLESS Account..."
sleep 2
;;

4)
break
;;

*)
echo "Invalid Option"
sleep 2
;;

esac

done

}
