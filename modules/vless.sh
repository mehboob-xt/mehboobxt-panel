#!/bin/bash

# =====================================
# MehboobXT VLESS Manager
# Module Version: 1.0.0
# =====================================

generate_uuid(){

uuid=$(generate_uuid)

echo "UUID: $uuid"

}

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
uuid=$(generate_uuid)

echo "UUID: $uuid"
sleep 3
;;

2)
echo "VLESS Account List"
echo "No account yet"
sleep 3
;;

3)
echo "Delete VLESS Account"
sleep 3
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
