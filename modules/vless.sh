#!/bin/bash

# =====================================
# MehboobXT VLESS Manager
# Module Version: 1.0.0
# =====================================


VLESS_DB="/etc/mehboobxt/vless_accounts.db"
PANEL_DIR="/etc/mehboobxt"
LOG_FILE="$PANEL_DIR/panel.log"


generate_uuid(){

    cat /proc/sys/kernel/random/uuid

}
panel_log(){

echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"

}

generate_vless_link(){

uuid=$1
name=$2

DOMAIN="tech.mehboobxt.ggff.net"
PORT="443"
PATH="/vless"

LINK="vless://$uuid@$DOMAIN:$PORT?type=ws&security=tls&host=$DOMAIN&path=$PATH&sni=$DOMAIN#$name"

echo ""
echo "🔗 VLESS LINK"
echo "--------------------------"
echo "$LINK"
echo "--------------------------"

}

show_vless_info(){

name=$1
uuid=$2
expiry=$3
status=$4
created=$5

echo ""
echo "=========================="
echo "🔐 MehboobXT VLESS Account"
echo "=========================="
echo ""
echo "Name      : $name"
echo "UUID      : $uuid"
echo "Created   : $created"
echo "Expiry    : $expiry"

today=$(date +%s)
expire_sec=$(date -d "$expiry" +%s)

remaining=$(( (expire_sec - today) / 86400 ))

if [ "$remaining" -lt 0 ]
then
remaining=0
fi

echo "Remaining : $remaining Days"
echo "Status    : $status"
echo ""
echo "=========================="

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
echo "4. Edit VLESS Account"
echo "5. Enable/Disable Account"
echo "6. Back"

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

created=$(date +%Y-%m-%d)

echo "$name|$uuid|$expiry|ACTIVE|$created" >> "$VLESS_DB"
panel_log "VLESS Account Created: $name"

echo ""
echo "✅ VLESS Account Saved"
show_vless_info "$name" "$uuid" "$expiry" "ACTIVE" "$created"
generate_vless_link "$uuid" "$name"

sleep 3

;;


2)

echo "VLESS Account List"
echo "--------------------------"

if [ -f "$VLESS_DB" ]
then

while IFS="|" read -r name uuid expiry status created

echo "--------------------------"
echo "Name   : $name"
echo "UUID   : $uuid"
echo "Expiry : $expiry"
echo "Created : $created"
echo "Status  : $status"

today=$(date +%s)
expire_sec=$(date -d "$expiry" +%s)

if [ "$expire_sec" -gt "$today" ]
then
status="ACTIVE"
else
status="EXPIRED"
fi

echo "Status    : $status"

done < "$VLESS_DB"

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

echo "Edit VLESS Account"

read -p "Enter UUID: " edituuid

if grep -Fq "$edituuid" "$VLESS_DB"
then

read -p "New Name: " newname
read -p "New Expiry Days: " days

newexpiry=$(date -d "+$days days" +"%Y-%m-%d")
created=$(date +%Y-%m-%d)

sed -i "\|$edituuid|c\\$newname|$edituuid|$newexpiry|ACTIVE|$created" "$VLESS_DB"

echo "✅ Account Updated"

else

echo "❌ UUID Not Found"

fi

sleep 3

;;

5)

echo "VLESS Account Status Control"

read -p "Enter UUID: " statusuuid


if grep -Fq "$statusuuid" "$VLESS_DB"
then

current_status=$(grep "$statusuuid" "$VLESS_DB" | cut -d"|" -f4)


if [ "$current_status" = "ACTIVE" ]
then

sed -i "\|$statusuuid|s|ACTIVE|DISABLED|" "$VLESS_DB"

echo "⚠️ Account Disabled"

else

sed -i "\|$statusuuid|s|DISABLED|ACTIVE|" "$VLESS_DB"

echo "✅ Account Enabled"

fi


else

echo "❌ UUID Not Found"

fi

sleep 3

;;

6)

break

;;


*)

echo "Invalid Option"

sleep 2

;;

esac


done

}
