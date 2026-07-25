#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../core/common.sh"
source "$SCRIPT_DIR/../core/colors.sh"
source "$SCRIPT_DIR/../core/config.sh"
source "$SCRIPT_DIR/../core/database.sh"
source "$SCRIPT_DIR/../core/config_generator.sh"

DB="$TROJAN_DB"

BACKUP="$TROJAN_BACKUP_DIR"

EXPORT="$TROJAN_EXPORT_DIR"

init_trojan_manager() {

    mkdir -p "$DATA_DIR"
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$EXPORT_DIR"

    mkdir -p "$BACKUP"
    mkdir -p "$EXPORT"

    touch "$DB"
}

trojan_menu() {

    init_trojan_manager

    while true
    do

        header

        echo "========== MehboobXT Trojan Manager =========="
echo ""
echo "1. Create Trojan User"
echo "2. List Trojan Users"
echo "3. Show Trojan User"
echo "4. Copy Trojan Link"
echo "5. Search Trojan User"
echo "6. Export Trojan Config"
echo "7. Renew Trojan User"
echo "8. Delete Trojan User"
echo "9. Backup Trojan Database"
echo "10. Restore Trojan Database"
echo "11. Trojan Statistics"
echo "12. Edit Trojan User"
echo "13. Generate_Trojan_link"
echo "14. Back"
echo ""

read -rp "Select Option : " option

case $option in

1)
create_trojan_user
;;

2)
list_trojan_users
;;

3)
show_trojan_user
;;

4)
copy_trojan_link
;;

5)
search_trojan_user
;;

6)
export_trojan_config
;;

7)
renew_trojan_user
;;

8)
delete_trojan_user
;;

9)
backup_trojan_db
;;

10)
restore_trojan_db
;;

11)
trojan_statistics
;;

12)
edit_trojan_user
;;

13)
generate_trojan_link
;;

14)
break
;;

*)
error "Invalid Option"
sleep 2
;;

esac

    done

}

create_trojan_user() {

    header

    echo "========== Create Trojan User =========="
    echo ""

    read -rp "Remark        : " REMARK
    read -rp "Password(UUID): " PASSWORD
    read -rp "Expiry Days   : " DAYS
    read -rp "Traffic (GB)  : " TRAFFIC

    echo ""
    echo "Select Trojan Type"
    echo "1. Trojan WS TLS"
    echo "2. Trojan WS Non-TLS"
    echo "3. Trojan WS TLS Proxy"
    echo ""

    read -rp "Option : " TYPE_OPTION

    case $TYPE_OPTION in
        1) TYPE="TLS" ;;
        2) TYPE="NON_TLS" ;;
        3) TYPE="TLS_PROXY" ;;
        *)
            error "Invalid Trojan Type"
            pause
            return
        ;;
    esac

    if [ -z "$REMARK" ]; then
        error "Remark cannot be empty"
        pause
        return
    fi

    if [ -z "$PASSWORD" ]; then
        PASSWORD=$(cat /proc/sys/kernel/random/uuid)
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

    if ! [[ "$TRAFFIC" =~ ^[0-9]+$ ]]; then
        error "Traffic must be a number"
        pause
        return
    fi

    if [ "$TRAFFIC" -le 0 ]; then
        error "Traffic must be greater than 0"
        pause
        return
    fi

    if [ -n "$(db_read "$DB" "$REMARK")" ]; then
        error "Trojan user already exists"
        pause
        return
    fi

    EXPIRY=$(date -d "$DAYS days" +"%Y-%m-%d")

    db_add "$DB" "$REMARK|$PASSWORD|$TYPE|$TRAFFIC|$EXPIRY"

    echo ""
    success "Trojan User Created Successfully"

    echo ""
    echo "Remark   : $REMARK"
    echo "Password : $PASSWORD"
    echo "Type     : $TYPE"
    echo "Traffic  : ${TRAFFIC} GB"
    echo "Expiry   : $EXPIRY"
    echo ""

    pause

}


list_trojan_users() {

    header

    echo "========== Trojan Users =========="
    echo ""

    if db_empty "$DB"; then
        error "No Trojan users found"
        pause
        return
    fi

    while IFS="|" read -r REMARK PASSWORD TYPE TRAFFIC EXPIRY
    do
        echo "Remark   : $REMARK"
        echo "Password : $PASSWORD"
        echo "Type     : $TYPE"
        echo "Traffic  : ${TRAFFIC} GB"
        echo "Expiry   : $EXPIRY"
        echo "----------------------------------------"
    done < "$DB"

    pause

}


show_trojan_user() {

    header

    echo "========== Show Trojan User =========="
    echo ""

    read -rp "Remark : " REMARK

    if [ ! -f "$DB" ]; then
        error "Database not found"
        pause
        return
    fi

    DATA=$(db_find "$DB" "$REMARK")

    if [ -z "$DATA" ]; then
        error "Trojan user not found"
        pause
        return
    fi

    IFS="|" read -r REMARK PASSWORD TYPE TRAFFIC EXPIRY <<< "$DATA"

    echo ""
    success "Trojan User Found"

    echo ""
    echo "========== Trojan User =========="
    echo ""
    echo "Remark   : $REMARK"
    echo "Password : $PASSWORD"
    echo "Type     : $TYPE"
    echo "Traffic  : ${TRAFFIC} GB"
    echo "Expiry   : $EXPIRY"
    echo "================================="
    echo ""

    pause

}

copy_trojan_link() {

    header

    echo "========== Copy Trojan Link =========="
    echo ""

    read -rp "Remark : " REMARK

    if [ ! -f "$DB" ]; then
        error "Database not found"
        pause
        return
    fi

    DATA=$(db_find "$DB" "$REMARK")

    if [ -z "$DATA" ]; then
        error "Trojan user not found"
        pause
        return
    fi

    IFS="|" read -r REMARK PASSWORD TYPE TRAFFIC EXPIRY <<< "$DATA"

    SERVER="$SERVER_DOMAIN"
    PORT="$TROJAN_PORT"

    case "$TYPE" in
        TLS)
            SECURITY="tls"
            ;;
        NON_TLS)
            SECURITY="none"
            ;;
        TLS_PROXY)
            SECURITY="tls"
            ;;
        *)
            SECURITY="tls"
            ;;
    esac

    LINK="trojan://${PASSWORD}@${SERVER}:${PORT}?security=${SECURITY}&type=ws#${REMARK}"

    echo ""
    success "Trojan Link Generated"
    echo ""
    echo "$LINK"
    echo ""

    if command -v xclip >/dev/null 2>&1; then
        echo -n "$LINK" | xclip -selection clipboard
        success "Copied to clipboard."
    fi

    pause

}

search_trojan_user() {

    header

    echo "========== Search Trojan User =========="
    echo ""

    read -rp "Search Remark : " KEYWORD

    if db_empty "$DB"; then
        error "No Trojan users found"
        pause
        return
    fi

    RESULT=$(grep -i "$KEYWORD" "$DB")

    if [ -z "$RESULT" ]; then
        error "No matching Trojan user found"
        pause
        return
    fi

    echo ""

    while IFS="|" read -r REMARK PASSWORD TYPE TRAFFIC EXPIRY
    do
        echo "Remark   : $REMARK"
        echo "Password : $PASSWORD"
        echo "Type     : $TYPE"
        echo "Traffic  : ${TRAFFIC} GB"
        echo "Expiry   : $EXPIRY"
        echo "--------------------------------------"
    done <<< "$RESULT"

    pause

}

export_trojan_config() {

    header

    echo "========== Export Trojan Config =========="
    echo ""

    read -rp "Remark : " REMARK

    DATA=$(db_find "$DB" "$REMARK")

    if [ -z "$DATA" ]; then
        error "Trojan user not found"
        pause
        return
    fi

    mkdir -p "$EXPORT"

    FILE="$EXPORT/${REMARK}.txt"

    echo "$DATA" > "$FILE"

    success "Config exported successfully."

    echo ""
    echo "$FILE"
    echo ""

    pause

}

renew_trojan_user() {

    header

    echo "========== Renew Trojan User =========="
    echo ""

    read -rp "Remark : " REMARK
    read -rp "Add Days : " DAYS

    if ! [[ "$DAYS" =~ ^[0-9]+$ ]]; then
        error "Invalid days"
        pause
        return
    fi

    DATA=$(db_find "$DB" "$REMARK")

    if [ -z "$DATA" ]; then
        error "Trojan user not found"
        pause
        return
    fi

    IFS="|" read -r NAME PASSWORD TYPE TRAFFIC EXPIRY <<< "$DATA"

    NEW_EXPIRY=$(date -d "$EXPIRY +$DAYS days" +"%Y-%m-%d")

    db_delete "$DB" "$REMARK"
    db_add "$DB" "$NAME|$PASSWORD|$TYPE|$TRAFFIC|$NEW_EXPIRY"

    success "Trojan user renewed."

    echo ""
    echo "New Expiry : $NEW_EXPIRY"
    echo ""

    pause

}

delete_trojan_user() {

    header

    echo "========== Delete Trojan User =========="
    echo ""

    read -rp "Remark : " REMARK

    DATA=$(db_find "$DB" "$REMARK")

    if [ -z "$DATA" ]; then
        error "Trojan user not found"
        pause
        return
    fi

    read -rp "Delete this user? (y/n): " CONFIRM

    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        error "Cancelled"
        pause
        return
    fi

    db_delete "$DB" "$REMARK"

    success "Trojan user deleted."

    pause

}

backup_trojan_db() {

    header

    echo "========== Backup Trojan Database =========="
    echo ""

    mkdir -p "$BACKUP"

    FILE="$BACKUP/trojan_$(date +%Y%m%d_%H%M%S).db"

    cp "$DB" "$FILE"

    success "Backup created successfully."

    echo ""
    echo "$FILE"
    echo ""

    pause

}

restore_trojan_db() {

    header

    echo "========== Restore Trojan Database =========="
    echo ""

    FILE=$(ls -t "$BACKUP"/*.db 2>/dev/null | head -n1)

    if [ -z "$FILE" ]; then
        error "No backup found"
        pause
        return
    fi

    cp "$FILE" "$DB"

    success "Database restored successfully."

    echo ""
    echo "Backup : $FILE"
    echo ""

    pause

}

trojan_statistics() {

    header

    echo "========== Trojan Statistics =========="
    echo ""

    TOTAL=$(wc -l < "$DB" 2>/dev/null)

    [ -z "$TOTAL" ] && TOTAL=0

    echo "Total Trojan Users : $TOTAL"

    echo ""

    pause

}

edit_trojan_user() {

    header

    echo "========== Edit Trojan User =========="
    echo ""

    read -rp "Remark : " REMARK

    DATA=$(db_find "$DB" "$REMARK")

    if [ -z "$DATA" ]; then
        error "Trojan user not found"
        pause
        return
    fi

    IFS="|" read -r NAME PASSWORD TYPE TRAFFIC EXPIRY <<< "$DATA"

    read -rp "New Traffic (GB) [$TRAFFIC]: " NEW_TRAFFIC
    read -rp "New Expiry Days (0=Keep): " DAYS

    [ -z "$NEW_TRAFFIC" ] && NEW_TRAFFIC="$TRAFFIC"

    if [ "$DAYS" != "0" ]; then
        EXPIRY=$(date -d "$DAYS days" +"%Y-%m-%d")
    fi

    db_delete "$DB" "$REMARK"
    db_add "$DB" "$NAME|$PASSWORD|$TYPE|$NEW_TRAFFIC|$EXPIRY"

    success "Trojan user updated."

    pause

}

generate_trojan_link() {

    header

    echo "========== Generate Trojan Link =========="
    echo ""

    read -rp "Remark : " REMARK

    DATA=$(db_find "$DB" "$REMARK")

    if [ -z "$DATA" ]; then
        error "Trojan user not found"
        pause
        return
    fi

    IFS="|" read -r NAME PASSWORD TYPE TRAFFIC EXPIRY <<< "$DATA"

    SERVER="${SERVER_DOMAIN:-your-domain.com}"
    PORT="${TROJAN_PORT:-443}"
    HOST="${TROJAN_HOST:-$SERVER}"
    PATH_WS="${TROJAN_WS_PATH:-/ws}"
    
case "$TYPE" in

    TLS)
    LINK=$(generate_tls_config)
;;

NON_TLS)
    LINK=$(generate_non_tls_config)
;;

TLS_PROXY)
    LINK=$(generate_tls_proxy_config)
;;
        *)
            error "Unknown Trojan type"
            pause
            return
            ;;
    esac

    echo ""
    success "Trojan Link Generated"
    echo ""
    echo "$LINK"
    echo ""

    pause

}
