#!/bin/bash

vmess_menu(){

while true
do

clear

echo "=========================="
echo "🔐 MehboobXT VMESS Manager"
echo "=========================="

echo "1. Create VMESS Account"
echo "2. List VMESS Account"
echo "3. Delete VMESS Account"
echo "4. Back"

echo ""

read -p "Select Option: " vmessopt

case $vmessopt in

1)
echo "Creating VMESS Account..."
uuid=$(cat /proc/sys/kernel/random/uuid)
echo "UUID: $uuid"
sleep 3
;;

2)
echo "VMESS Account List"
echo "No account yet"
sleep 3
;;

3)
echo "Delete VMESS Account"
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
