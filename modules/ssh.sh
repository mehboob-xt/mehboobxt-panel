#!/bin/bash

ssh_menu() {

while true
do

header

echo "========= SSH Manager ========="
echo ""
echo "1. Create SSH User"
echo "2. List SSH Users"
echo "3. Delete SSH User"
echo "4. Change Password"
echo "5. Extend Expiry"
echo "6. Online Users"
echo "7. Back"
echo ""

read -rp "Select Option: " option

case $option in

1)
create_ssh_user
;;

2)
list_ssh_users
;;

3)
delete_ssh_user
;;

4)
change_ssh_password
;;

5)
extend_ssh_expiry
;;

6)
show_online_users
;;

7)
break
;;

*)
error "Invalid Option"
sleep 2
;;

esac

done

}

create_ssh_user() {

header

read -rp "Username : " user
read -rp "Password : " pass
read -rp "Expiry Days : " days

if id "$user" >/dev/null 2>&1; then
    error "User already exists"
    sleep 2
    return
fi

useradd -e $(date -d "$days days" +"%Y-%m-%d") -M -s /bin/false "$user"

echo "$user:$pass" | chpasswd

success "SSH User Created"
echo ""
echo "Username : $user"
echo "Password : $pass"
echo "Expiry   : $(date -d "$days days" +"%Y-%m-%d")"

pause

}

list_ssh_users() {

header

echo "=========== SSH Users ==========="

awk -F: '$3>=1000 && $1!="nobody" {
    printf "%-20s %-20s\n",$1,$8
}' /etc/passwd

echo ""
pause

}

delete_ssh_user() {

header

read -rp "Username : " user

if ! id "$user" >/dev/null 2>&1; then
    error "User not found"
    sleep 2
    return
fi

userdel -r "$user" 2>/dev/null

success "SSH User Deleted"

pause

}

change_ssh_password() {

header

read -rp "Username : " user

if ! id "$user" >/dev/null 2>&1; then
    error "User not found"
    sleep 2
    return
fi

read -rsp "New Password : " pass
echo

echo "$user:$pass" | chpasswd

success "Password Updated"

pause

}

extend_ssh_expiry() {

header

read -rp "Username : " user

if ! id "$user" >/dev/null 2>&1; then
    error "User not found"
    sleep 2
    return
fi

read -rp "Extend Days : " days

expiry=$(date -d "$days days" +"%Y-%m-%d")

chage -E "$expiry" "$user"

success "Expiry Extended"

echo ""
echo "User   : $user"
echo "Expiry : $expiry"

pause

}

show_online_users() {

header

echo "========== Online SSH Users =========="

who

echo ""
pause

}
