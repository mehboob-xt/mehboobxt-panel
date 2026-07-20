#!/bin/bash

trojan_menu(){

while true
do

clear

echo "=========================="
echo "🔐 MehboobXT Trojan Manager"
echo "=========================="

echo "1. Create Trojan Account"
echo "2. List Trojan Account"
echo "3. Delete Trojan Account"
echo "4. Back"

echo ""

read -p "Select Option: " trojanopt

case $trojanopt in

1)
echo "Creating Trojan Account..."
password=$(openssl rand -hex 8)
echo "Password: $password"
sleep 3
;;

2)
echo "Trojan Account List"
echo "No account yet"
sleep 3
;;

3)
echo "Delete Trojan Account"
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
