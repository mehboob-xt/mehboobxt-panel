#!/bin/bash

vless_menu() {

while true
do

header

echo "========== VLESS Manager =========="
echo ""
echo "1. Create VLESS User"
echo "2. List VLESS Users"
echo "3. Show VLESS User"
echo "4. Renew VLESS User"
echo "5. Delete VLESS User"
echo "6. Back"
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
show_vless_user
;;

4)
renew_vless_user
;;

5)
delete_vless_user
;;

6)
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

if [ -z "$user" ]; then
    error "Username cannot be empty"
    pause
    return
fi

if ! [[ "$days" =~ ^[0-9]+$ ]]; then
    error "Expiry must be a number"
    pause
    return
fi

if [ "$days" -le 0 ]; then
    error "Expiry must be greater than 0"
    pause
    return
fi

UUID=$(cat /proc/sys/kernel/random/uuid)

DB="/etc/mehboobxt/vless_accounts.db"
DOMAIN="tech.mehboobxt.ggff.net"
PORT="443"
TYPE="ws"
SECURITY="tls"
PATH="/vless"
SNI="$DOMAIN"

mkdir -p /etc/mehboobxt

touch "$DB"

if grep -q "^$user|" "$DB"; then
    error "Username already exists"
    pause
    return
fi

echo "$user|$UUID|$(date -d "$days days" +%Y-%m-%d)" >> "$DB"

echo ""
success "VLESS User Created"

echo ""
echo "Username : $user"
echo "UUID     : $UUID"
echo "Expiry   : $(date -d "$days days" +"%Y-%m-%d")"

LINK="vless://$UUID@$DOMAIN:$PORT?type=$TYPE&security=$SECURITY&encryption=none&path=$PATH&sni=$SNI#$user"
echo ""
echo "VLESS Link:"
echo "$LINK"

pause

}
list_vless_users() {

header

DB="/etc/mehboobxt/vless_accounts.db"

echo "========== VLESS Users =========="
echo ""

if [ ! -f "$DB" ]; then
    echo "No users found."
else
    while IFS="|" read -r USER UUID EXPIRY
do

    TODAY=$(date +%Y-%m-%d)

    if [[ "$EXPIRY" < "$TODAY" ]]; then
        STATUS="Expired"
    else
        STATUS="Active"
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Username : $USER"
    echo "UUID     : $UUID"
    echo "Expiry   : $EXPIRY"
    echo "Status   : $STATUS"

done < "$DB"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi

echo ""

pause

}

show_vless_user() {

    header

    DB="/etc/mehboobxt/vless_accounts.db"

    DOMAIN="tech.mehboobxt.ggff.net"
    PORT="443"
    TYPE="ws"
    SECURITY="tls"
    PATH="/vless"
    SNI="$DOMAIN"

    read -rp "Username : " user

    if [ ! -f "$DB" ]; then
        error "Database not found"
        pause
        return
    fi

    DATA=$(grep "^$user|" "$DB")

    if [ -z "$DATA" ]; then
        error "User not found"
        pause
        return
    fi

    IFS="|" read -r USER UUID EXPIRY <<< "$DATA"

    TODAY=$(date +%Y-%m-%d)

    if [[ "$EXPIRY" < "$TODAY" ]]; then
        STATUS="Expired"
    else
        STATUS="Active"
    fi

    
    LINK="vless://$UUID@$DOMAIN:$PORT?type=$TYPE&security=$SECURITY&encryption=none&path=$PATH&sni=$SNI#$USER"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Username : $USER"
    echo "UUID     : $UUID"
    echo "Expiry   : $EXPIRY"
    echo "Status   : $STATUS"
    echo ""
    echo "VLESS Link:"
    echo "$LINK"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━"

    pause
}


delete_vless_user() {

header

echo "Delete VLESS User"

read -rp "Username : " user

DB="/etc/mehboobxt/vless_accounts.db"

if [ ! -f "$DB" ]; then
    error "Database not found"
    pause
    return
fi

if ! grep -q "^$user|" "$DB"; then
    error "User not found"
    pause
    return
fi

grep -v "^$user|" "$DB" > /tmp/vless.tmp
mv /tmp/vless.tmp "$DB"

success "VLESS User Deleted"

pause
