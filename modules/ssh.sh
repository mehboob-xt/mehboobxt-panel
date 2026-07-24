#!/bin/bash

BASE="/etc/mehboobxt"

DB="$BASE/ssh_accounts.db"
BACKUP="$BASE/backup/ssh"
EXPORT="$BASE/export/ssh"

init_ssh_manager() {

    mkdir -p "$BASE"
    mkdir -p "$BACKUP"
    mkdir -p "$EXPORT"

    touch "$DB"

}

ssh_menu() {

init_ssh_manager

while true
do

header

echo "========== MehboobXT SSH Manager =========="
echo ""
echo "1. Create SSH User"
echo "2. List SSH Users"
echo "3. Show SSH User"
echo "4. Search SSH User"
echo "5. Renew SSH User"
echo "6. Delete SSH User"
echo "7. Change Password"
echo "8. Lock SSH User"
echo "9. Unlock SSH User"
echo "10. Online SSH Users"
echo "11. SSH Statistics"
echo "12. Backup SSH Database"
echo "13. Restore SSH Database"
echo "14. Edit SSH User"
echo "15. Export SSH Config"
echo "16. Back"
echo ""

read -rp "Select Option : " option

case $option in

1)
create_ssh_user
;;

2)
list_ssh_users
;;

3)
show_ssh_user
;;

4)
search_ssh_user
;;

5)
renew_ssh_user
;;

6)
delete_ssh_user
;;

7)
change_ssh_password
;;

8)
lock_ssh_user
;;

9)
unlock_ssh_user
;;

10)
show_online_users
;;

11)
ssh_statistics
;;

12)
backup_ssh_db
;;

13)
restore_ssh_db
;;

14)
edit_ssh_user
;;

15)
export_ssh_config
;;

16)
break
;;

*)
error "Invalid Option"
sleep 2
;;

esac
# Menu yahan hoga

done

}

create_ssh_user() {

    header

    echo "Create SSH User"
    echo ""

    read -rp "Username     : " USER
    read -rp "Password     : " PASS
    read -rp "Expiry Days  : " DAYS

    if [ -z "$USER" ]; then
    error "Username cannot be empty"
    pause
    return
fi

if [ -z "$PASS" ]; then
    error "Password cannot be empty"
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

if id "$USER" >/dev/null 2>&1; then
    error "Username already exists"
    pause
    return
fi

echo ""
# Expiry Date
EXPIRY=$(date -d "$DAYS days" +"%Y-%m-%d")

useradd \
-e "$EXPIRY" \
-M \
-s /usr/sbin/nologin \
"$USER"

echo "$USER:$PASS" | chpasswd

echo "$USER|$PASS|$EXPIRY" >> "$DB"

echo ""
success "SSH User Created Successfully"

echo ""
echo "Username : $USER"
echo "Password : $PASS"
echo "Expiry   : $EXPIRY"

pause

}

list_ssh_users() {

    header

    echo "========== SSH Users =========="
    echo ""

    if [ ! -s "$DB" ]; then
        error "No SSH users found"
        pause
        return
    fi

    while IFS="|" read -r USER PASS EXPIRY
    do
        echo "Username : $USER"
        echo "Password : $PASS"
        echo "Expiry   : $EXPIRY"
        echo "-----------------------------"
    done < "$DB"

    pause

}

show_ssh_user() {

    header

read -rp "Username : " USER

    if [ ! -f "$DB" ]; then
        error "Database not found"
        pause
        return
    fi

    DATA=$(grep -m1 "^$USER|" "$DB")

    if [ -z "$DATA" ]; then
        error "SSH User not found"
        pause
        return
    fi

    IFS="|" read -r USER PASS EXPIRY <<< "$DATA"

    echo ""
success "SSH User Found"

echo ""
echo "========== SSH User =========="
echo ""
echo "Username : $USER"
echo "Password : $PASS"
echo "Expiry   : $EXPIRY"
echo "=============================="
echo ""

pause

}

search_ssh_user() {

    header

    echo "========== Search SSH User =========="
    echo ""

    read -rp "Search Username : " SEARCH

    if [ ! -f "$DB" ]; then
        error "Database not found"
        pause
        return
    fi

    if [ -z "$SEARCH" ]; then
    error "Search cannot be empty"
    pause
    return
    fi

    RESULT=$(grep -i "$SEARCH" "$DB")

    if [ -z "$RESULT" ]; then
        error "No matching SSH user found"
        pause
        return
    fi

    echo ""

    while IFS="|" read -r USER PASS EXPIRY
    do
        echo "Username : $USER"
        echo "Password : $PASS"
        echo "Expiry   : $EXPIRY"
        echo "-----------------------------"
    done <<< "$RESULT"

    pause

}

renew_ssh_user() {

    header

    echo "========== Renew SSH User =========="
    echo ""

    read -rp "Username     : " USER
    read -rp "Extra Days   : " DAYS

    if ! grep -q "^$USER|" "$DB"; then
        error "SSH User not found"
        pause
        return
    fi

    if ! [[ "$DAYS" =~ ^[0-9]+$ ]]; then
        error "Days must be a number"
        pause
        return
    fi

    EXPIRY=$(date -d "$DAYS days" +"%Y-%m-%d")

    usermod -e "$EXPIRY" "$USER"

    PASS=$(grep "^$USER|" "$DB" | cut -d'|' -f2)

    sed -i "/^$USER|/d" "$DB"
    echo "$USER|$PASS|$EXPIRY" >> "$DB"

    echo ""
    success "SSH User Renewed Successfully"
    echo ""
    echo "Username : $USER"
    echo "Expiry   : $EXPIRY"

    pause

}
delete_ssh_user() {

    header

    echo "========== Delete SSH User =========="
    echo ""

    read -rp "Username : " USER

    if ! id "$USER" >/dev/null 2>&1; then
        error "SSH User not found"
        pause
        return
    fi

    userdel -f "$USER"

    sed -i "/^$USER|/d" "$DB"

    echo ""
    success "SSH User Deleted Successfully"
    echo ""
    echo "Username : $USER"

    pause

}

change_ssh_password() {

    header

    echo "========== Change SSH Password =========="
    echo ""

    read -rp "Username     : " USER
    read -rp "New Password : " PASS

    if ! id "$USER" >/dev/null 2>&1; then
        error "SSH User not found"
        pause
        return
    fi

    echo "$USER:$PASS" | chpasswd

    EXPIRY=$(grep "^$USER|" "$DB" | cut -d'|' -f3)

    sed -i "/^$USER|/d" "$DB"
    echo "$USER|$PASS|$EXPIRY" >> "$DB"

    echo ""
    success "Password Changed Successfully"
    echo ""
    echo "Username : $USER"

    pause

}

lock_ssh_user() {

    header

    echo "========== Lock SSH User =========="
    echo ""

    read -rp "Username : " USER

    if ! id "$USER" >/dev/null 2>&1; then
        error "SSH User not found"
        pause
        return
    fi

    passwd -l "$USER"

    echo ""
    success "SSH User Locked Successfully"
    echo ""
    echo "Username : $USER"

    pause

}

unlock_ssh_user() {

    header

    echo "========== Unlock SSH User =========="
    echo ""

    read -rp "Username : " USER

    if ! id "$USER" >/dev/null 2>&1; then
        error "SSH User not found"
        pause
        return
    fi

    passwd -u "$USER"

    echo ""
    success "SSH User Unlocked Successfully"
    echo ""
    echo "Username : $USER"

    pause

}

show_online_users() {

    header

    echo "========== Online SSH Users =========="
    echo ""

    if who | grep -q .; then
        who
    else
        echo "No SSH users are currently online."
    fi

    echo ""
    pause

}

ssh_statistics() {

    header

    echo "========== SSH Statistics =========="
    echo ""

    TOTAL=$(wc -l < "$DB")

    ONLINE=$(who | awk '{print $1}' | sort -u | wc -l)

    echo "Total Users  : $TOTAL"
    echo "Online Users : $ONLINE"

    echo ""

    pause

}

backup_ssh_db() {

    header

    echo "========== Backup SSH Database =========="
    echo ""

    FILE="$BACKUP/ssh_backup_$(date +%Y%m%d_%H%M%S).db"

    cp "$DB" "$FILE"

    success "Backup Created"

    echo ""
    echo "Saved To:"
    echo "$FILE"

    pause

}

restore_ssh_db() {

    header

    echo "========== Restore SSH Database =========="
    echo ""

    ls "$BACKUP"

    echo ""

    read -rp "Backup File : " FILE

    if [ ! -f "$BACKUP/$FILE" ]; then
        error "Backup not found"
        pause
        return
    fi

    cp "$BACKUP/$FILE" "$DB"

    success "Database Restored"

    pause

}

edit_ssh_user() {

    header

    echo "========== Edit SSH User =========="
    echo ""

    read -rp "Current Username : " OLDUSER
    read -rp "New Username     : " NEWUSER

    if ! id "$OLDUSER" >/dev/null 2>&1; then
        error "SSH User not found"
        pause
        return
    fi

    usermod -l "$NEWUSER" "$OLDUSER"

    PASS=$(grep "^$OLDUSER|" "$DB" | cut -d'|' -f2)
    EXPIRY=$(grep "^$OLDUSER|" "$DB" | cut -d'|' -f3)

    sed -i "/^$OLDUSER|/d" "$DB"
    echo "$NEWUSER|$PASS|$EXPIRY" >> "$DB"

    success "SSH User Updated"

    pause

}

export_ssh_config() {

    header

    echo "========== Export SSH Config =========="
    echo ""

    read -rp "Username : " USER

    DATA=$(grep "^$USER|" "$DB")

    if [ -z "$DATA" ]; then
        error "SSH User not found"
        pause
        return
    fi

    IFS="|" read -r USER PASS EXPIRY <<< "$DATA"

    FILE="$EXPORT/$USER.txt"

    cat > "$FILE" <<EOF
========== MehboobXT SSH ==========
Username : $USER
Password : $PASS
Expiry   : $EXPIRY
===================================
EOF

    success "Config Exported"

    echo ""
    echo "Saved To:"
    echo "$FILE"

    pause

}
