#!/bin/bash

referral_menu(){

while true
do

clear

echo "=============================="
echo "🎁 MehboobXT Referral System"
echo "=============================="

echo "1. Generate Referral Code"
echo "2. Check Referral Reward"
echo "3. Referral History"
echo "4. Back"

echo ""

read -p "Select Option: " refopt

case $refopt in

1)
echo "Generating Referral Code..."
code="MXT$(shuf -i 10000-99999 -n 1)"
echo "Your Referral Code: $code"
sleep 3
;;

2)
echo "Checking Referral Reward..."
echo "No referral reward yet"
sleep 3
;;

3)
echo "Referral History"
echo "No referral data"
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
