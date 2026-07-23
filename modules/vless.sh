#!/bin/bash

vless_menu() {

while true
do

header

echo "========== VLESS Manager =========="
echo ""
echo "1. Create VLESS User"
echo "2. List VLESS Users"
echo "3. Delete VLESS User"
echo "4. Back"
echo ""

read -rp "Select Option : " option

case $option in

1)

create_vless_user

;;

2)

list_vless_users

;;

3)

delete_vless_user

;;

4)

break

;;

*)

error "Invalid Option"
sleep 2

;;

esac

done

}

create_vless_user() {

header

echo "Create VLESS User"

read -rp "Username : " user
read -rp "Expiry Days : " days

UUID=$(cat /proc/sys/kernel/random/uuid)

DB="/etc/mehboobxt/vless_accounts.db"

mkdir -p /etc/mehboobxt

touch "$DB"

echo "$user|$UUID|$(date -d "$days days" +%Y-%m-%d)" >> "$DB"

echo ""
success "VLESS User Created"

echo ""
echo "Username : $user"
echo "UUID     : $UUID"
echo "Expiry   : $(date -d "$days days" +%Y-%m-%d)"

pause

}

list_vless_users() {

header

echo "========== VLESS Users =========="
echo ""

list_vless_users() {

header

DB="/etc/mehboobxt/vless_accounts.db"

echo "========== VLESS Users =========="
echo ""

if [ ! -f "$DB" ]; then
    echo "No users found."
else
    column -t -s "|" "$DB"
fi

echo ""

pause

}

echo ""

pause

}

delete_vless_user() {

header

echo "Delete VLESS User"

read -rp "Username : " user

success "VLESS User Deleted"

pause

}

