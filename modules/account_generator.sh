#!/bin/bash

account_generator(){

while true
do

clear

echo "=============================="
echo "🚀 MehboobXT Account Generator"
echo "=============================="

echo "1. Generate SSH Account"
echo "2. Generate VLESS Account"
echo "3. Generate VMESS Account"
echo "4. Generate Trojan Account"
echo "5. Back"

echo ""

read -p "Select Option: " genopt

case $genopt in

1)
echo "Generating SSH Account..."
username="user$(shuf -i 1000-9999 -n 1)"
password="$(openssl rand -hex 4)"
echo "Username: $username"
echo "Password: $password"
sleep 3
;;

2)
echo "Generating VLESS Account..."
uuid=$(cat /proc/sys/kernel/random/uuid)
echo "UUID: $uuid"
sleep 3
;;

3)
echo "Generating VMESS Account..."
uuid=$(cat /proc/sys/kernel/random/uuid)
echo "UUID: $uuid"
sleep 3
;;

4)
echo "Generating Trojan Account..."
password=$(openssl rand -hex 8)
echo "Password: $password"
sleep 3
;;

5)
break
;;

*)
echo "Invalid Option"
sleep 2
;;

esac

done

}
