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

}

renew_ssh_user() {

}

delete_ssh_user() {

}

change_ssh_password() {

}

lock_ssh_user() {

}

unlock_ssh_user() {

}

show_online_users() {

}

ssh_statistics() {

}

backup_ssh_db() {

}

restore_ssh_db() {

}

edit_ssh_user() {

}

export_ssh_config() {

}
