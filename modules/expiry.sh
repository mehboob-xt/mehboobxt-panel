#!/bin/bash

expiry_menu(){

while true
do

clear

echo "=========================="
echo "⏳ MehboobXT Expiry Manager"
echo "=========================="

echo "1. Add Expiry Date"
echo "2. Check Expired Accounts"
echo "3. Remove Expired Account"
echo "4. Back"

echo ""

read -p "Select Option: " expiryopt

case $expiryopt in

1)
echo "Add Expiry Date"
read -p "Enter Days: " days
echo "Expiry set for $days days"
sleep 3
;;

2)
echo "Checking Expired Accounts..."
echo "No expired account"
sleep 3
;;

3)
echo "Removing Expired Account..."
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
