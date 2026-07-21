#!/bin/bash

# =====================================
# MehboobXT VLESS Manager
# Module Version: 1.0.0
# =====================================


VLESS_DB="/etc/mehboobxt/vless_accounts.db"


generate_uuid(){

    cat /proc/sys/kernel/random/uuid

}


vless_menu(){

mkdir -p /etc/mehboobxt


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

read -p "Account Name: " name

if [ -z "$name" ]
then
echo "❌ Name Required"
sleep 2
continue
fi

uuid=$(generate_uuid)

read -p "Expiry Days: " days

expiry=$(date -d "+$days days" +"%Y-%m-%d")

echo ""
echo "UUID: $uuid"
echo "Expiry: $expiry"

echo "$name|$uuid|$expiry" >> "$VLESS_DB"

echo ""
echo "✅ VLESS Account Saved"

sleep 3

;;


2)

echo "VLESS Account List"
echo "--------------------------"

if [ -f "$VLESS_DB" ]
then

cat "$VLESS_DB"

else

echo "No account yet"

fi

sleep 3

;;


3)

echo "Delete VLESS Account"

read -p "Enter UUID: " deluuid

if [ -z "$deluuid" ]
then
echo "❌ UUID Required"
sleep 2
continue
fi


if [ -f "$VLESS_DB" ]
then

if grep -Fq "$deluuid" "$VLESS_DB"
then

sed -i "\|$deluuid|d" "$VLESS_DB"

echo "✅ Account Deleted"

else

echo "❌ UUID Not Found"

fi

else

echo "❌ No Database Found"

fi


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
