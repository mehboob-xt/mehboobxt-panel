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
echo "4. Copy VLESS Link"
echo "5. Search VLESS User"
echo "6. Export VLESS Config"
echo "7. Renew VLESS User"
echo "8. Delete VLESS User"
echo "9. Backup VLESS Database"
echo "10. Restore VLESS Database"
echo "11. VLESS Statistics"
echo "12. Edit VLESS User"
echo "13. Back"
echo ""

read -rp "Select Option : " option

case $option in

1)create_vless_user
;;

2)list_vless_users
;;

3)show_vless_user
;;

4)
search_vless_user
;;

5)
copy_vless_link
;;

6)
export_vless_config
;;

7)
renew_vless_user
;;

8)
delete_vless_user
;;

9)
backup_vless_db
;;

10)
restore_vless_db
;;

11)
vless_statistics
;;

12)
edit_vless_user
;;

13)
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

DB="$VLESS_DB"
DOMAIN="$VLESS_DOMAIN"
PORT="$VLESS_PORT"
TYPE="$VLESS_NETWORK"
SECURITY="$VLESS_SECURITY"
PATH="$VLESS_PATH"
SNI="$DOMAIN"

mkdir -p "$DATA_DIR"
touch "$DB"

if db_read -q "$DB" "$user"; then
    error "Username already exists"
    pause
    return
fi

db_add "$DB" "$user|$UUID|$(date -d "$days days" +%Y-%m-%d)"

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

renew_vless_user() {

    header

    echo "Renew VLESS User"

    DB="$VLESS_DB"

    read -rp "Username : " user
    read -rp "Renew Days : " days

    if [ -z "$user" ]; then
        error "Username cannot be empty"
        pause
        return
    fi

    if ! [[ "$days" =~ ^[0-9]+$ ]]; then
        error "Renew days must be a number"
        pause
        return
    fi

    if [ "$days" -le 0 ]; then
        error "Renew days must be greater than 0"
        pause
        return
    fi

    if [ ! -f "$DB" ]; then
        error "Database not found"
        pause
        return
    fi

    if ! db_read "$DB" "$user"; then
        error "User not found"
        pause
        return
    fi

    success "Validation Successful"

    DATA=$(db_read "$DB" "$user")

IFS="|" read -r USER UUID EXPIRY <<< "$DATA"

TODAY=$(date +%Y-%m-%d)

if [[ "$EXPIRY" < "$TODAY" ]]; then
    BASE_DATE="$TODAY"
else
    BASE_DATE="$EXPIRY"
fi

NEW_EXPIRY=$(date -d "$BASE_DATE +$days days" +%Y-%m-%d)

db_update "$DB" "$USER" "$USER|$UUID|$NEW_EXPIRY"

echo ""
success "VLESS User Renewed"

echo ""
echo "Username : $USER"
echo "Old Expiry : $EXPIRY"
echo "New Expiry : $NEW_EXPIRY"

    pause
}

copy_vless_link() {

    header

    echo "Copy VLESS Link"

    DB="$VLESS_DB"
    DOMAIN="$VLESS_DOMAIN"
    PORT="$VLESS_PORT"
    TYPE="$VLESS_NETWORK"
    SECURITY="$VLESS_SECURITY"
    PATH="$VLESS_PATH"
    SNI="$DOMAIN"

    read -rp "Username : " user

    if [ ! -f "$DB" ]; then
        error "Database not found"
        pause
        return
    fi

    DATA=$(db_read "$DB" "$user")

    if [ -z "$DATA" ]; then
        error "User not found"
        pause
        return
    fi

    IFS="|" read -r USER UUID EXPIRY <<< "$DATA"

    LINK="vless://$UUID@$DOMAIN:$PORT?type=$TYPE&security=$SECURITY&encryption=none&path=$PATH&sni=$SNI#$USER"

    echo ""
    success "VLESS Link Generated"
    echo ""
    echo "Username : $USER"
    echo "Expiry   : $EXPIRY"
    echo ""
    echo "VLESS Link:"
    echo "$LINK"
    echo ""

    pause
}


list_vless_users() {

header

DB="$VLESS_DB"

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

    DB="$VLESS_DB"

    DOMAIN="$VLESS_DOMAIN"
    PORT="$VLESS_PORT"
    TYPE="$VLESS_NETWORK"
    SECURITY="$VLESS_SECURITY"
    PATH="$VLESS_PATH"
    SNI="$DOMAIN"

    read -rp "Username : " user

    if [ ! -f "$DB" ]; then
        error "Database not found"
        pause
        return
    fi

    DATA=$(db_read "$DB" "$user")
    
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

search_vless_user() {

    header

    echo "Search VLESS User"

    DB="$VLESS_DB"

    read -rp "Username : " user

    if [ ! -f "$DB" ]; then
        error "Database not found"
        pause
        return
    fi

    DATA=$(db_read "$DB" "$user")

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

    echo ""
    success "User Found"
    echo ""
    echo "Username : $USER"
    echo "UUID     : $UUID"
    echo "Expiry   : $EXPIRY"
    echo "Status   : $STATUS"
    echo ""

    pause
}


delete_vless_user() {

header

echo "Delete VLESS User"

read -rp "Username : " user

DB="$VLESS_DB"

if [ ! -f "$DB" ]; then
    error "Database not found"
    pause
    return
fi

if ! db_read "$DB" "$user"; then
    error "User not found"
    pause
    return
fi

db_delete "$DB" "$user"

success "VLESS User Deleted"

pause

}

backup_vless_db() {

    header

    echo "Backup VLESS Database"

    DB="$VLESS_DB"
    BACKUP_PATH="$BACKUP_PATH"
    
    mkdir -p "$BACKUP_PATH"

    FILE="$BACKUP_PATH/vless_backup_$(date +%Y%m%d_%H%M%S).db"
    
    if [ ! -f "$DB" ]; then
    error "Database not found"
    pause
    return
    fi

    cp "$DB" "$FILE"

    success "Backup Created"

    echo ""
    echo "Saved To:"
    echo "$FILE"
    echo ""

    pause
}

restore_vless_db() {

    header

    echo "Restore VLESS Database"

    BACKUP_PATH="$BACKUP_PATH"
    DB="$VLESS_DB"

    if [ ! -d "$BACKUP_PATH" ]; then
        error "Backup directory not found"
        pause
        return
    fi

    echo ""
    ls -1 "$BACKUP_PATH"
    echo ""

    read -rp "Backup File : " FILE

    if [ ! -f "$BACKUP_PATH/$FILE" ]; then
        error "Backup file not found"
        pause
        return
    fi

    cp "$BACKUP_PATH/$FILE" "$DB"

    success "Database Restored"

    echo ""
    echo "Restored From:"
    echo "$BACKUP_PATH/$FILE"
    echo ""

    pause
}

vless_statistics() {

    header

    DB="$VLESS_DB"

    if [ ! -f "$DB" ]; then
        error "Database not found"
        pause
        return
    fi

    TODAY=$(date +%Y-%m-%d)

    TOTAL=$(wc -l < "$DB")
    ACTIVE=0
    EXPIRED=0

    while IFS="|" read -r USER UUID EXPIRY
    do
        if [[ "$EXPIRY" < "$TODAY" ]]; then
            ((EXPIRED++))
        else
            ((ACTIVE++))
        fi
    done < "$DB"

    echo ""
    echo "========== VLESS Statistics =========="
    echo ""
    echo "Total Users   : $TOTAL"
    echo "Active Users  : $ACTIVE"
    echo "Expired Users : $EXPIRED"
    echo ""

    pause
}

edit_vless_user() {

    header

    echo "Edit VLESS User"

    DB="$VLESS_DB"

    read -rp "Current Username : " OLDUSER
    read -rp "New Username : " NEWUSER
    read -rp "New Expiry Days : " DAYS
    
    if [ -z "$OLDUSER" ] || [ -z "$NEWUSER" ]; then
    error "Username cannot be empty"
    pause
    return
fi

if [ "$OLDUSER" != "$NEWUSER" ] && db_read "$DB" "$NEWUSER" >/dev/null; then
    error "Username already exists"
    pause
    return
fi

if ! [[ "$DAYS" =~ ^[0-9]+$ ]]; then
    error "Expiry days must be a number"
    pause
    return
fi

if [ "$DAYS" -le 0 ]; then
    error "Expiry days must be greater than 0"
    pause
    return
fi

if [ ! -f "$DB" ]; then
    error "Database not found"
    pause
    return
fi

DATA=$(db_read "$DB" "$OLDUSER")

if [ -z "$DATA" ]; then
    error "User not found"
    pause
    return
fi

IFS="|" read -r USER UUID EXPIRY <<< "$DATA"

TODAY=$(date +%Y-%m-%d)

if [[ "$EXPIRY" < "$TODAY" ]]; then
    BASE_DATE="$TODAY"
else
    BASE_DATE="$EXPIRY"
fi

NEW_EXPIRY=$(date -d "$BASE_DATE +$DAYS days" +%Y-%m-%d)

db_update "$DB" "$OLDUSER" "$NEWUSER|$UUID|$NEW_EXPIRY"

  success "VLESS User Updated"

echo ""
echo "Old Username : $OLDUSER"
echo "New Username : $NEWUSER"
echo "UUID         : $UUID"
echo "New Expiry   : $NEW_EXPIRY"
echo ""

pause

}
    
export_vless_config() {

    header

    echo "Export VLESS Config"

    DB="$VLESS_DB"
    EXPORT_PATH="$EXPORT_DIR"
    DOMAIN="$VLESS_DOMAIN"
    PORT="$VLESS_PORT"
    TYPE="$VLESS_NETWORK"
    SECURITY="$VLESS_SECURITY"
    PATH="$VLESS_PATH"
    SNI="$DOMAIN"

    mkdir -p "$EXPORT_PATH"

    read -rp "Username : " user

    if [ ! -f "$DB" ]; then
        error "Database not found"
        pause
        return
    fi

    DATA=$(db_read "$DB" "$user")

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

    FILE="$EXPORT_PATH/$USER.txt"

    cat > "$FILE" <<EOF
Username : $USER
UUID     : $UUID
Expiry   : $EXPIRY
Status   : $STATUS

VLESS Link:
$LINK
EOF

    success "Config Exported"

    echo ""
    echo "Saved To:"
    echo "$FILE"
    echo ""

    pause
}
