#!/bin/bash

expiry_menu(){

while true
do

clear

echo "=========================="
echo " 🔐 MehboobXT Expiry Manager"
echo "=========================="

echo "1. Set User Expiry"
echo "2. Check Expiry"
echo "3. Back"

echo ""

read -p "Select Option: " expopt


case $expopt in

1)

read -p "Username: " user
read -p "Days: " days

if id "$user" >/dev/null 2>&1
then

expire_date=$(date -d "+$days days" +"%Y-%m-%d")

chage -E $(date -d "$expire_date" +%d) "$user"

echo "✅ Expiry Set"
echo "User: $user"
echo "Expire: $expire_date"

else

echo "❌ User Not Found"

fi

sleep 2
;;

2)

read -p "Username: " user

chage -l "$user"

sleep 3
;;

3)

break
;;

*)

echo "Invalid Option"
sleep 2
;;

esac

done

}
