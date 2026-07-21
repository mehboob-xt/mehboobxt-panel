#!/bin/bash
# =====================================
# MehboobXT SSH Manager
# Module Version: 1.0.0
# =====================================

ssh_menu(){

if ! check_command useradd
then
    install_package passwd
fi

while true
do

clear

echo "━━━━━━━━━━━━━━━━━━━━━━"
echo " 🔐 MehboobXT SSH Manager"
echo "━━━━━━━━━━━━━━━━━━━━━━"

echo "1. Create SSH User"
echo "2. Delete SSH User"
echo "3. List SSH Users"
echo "4. Back"

echo ""
read -p "Select Option: " sshopt


case $sshopt in

1)

read -p "Username: " user
read -p "Password: " pass

if id "$user" >/dev/null 2>&1
then
    echo "❌ User already exists"
else
    useradd -m -s /bin/bash "$user"
echo "$user:$pass" | chpasswd

success "SSH User Created"
echo "Username: $user"
echo "Shell: /bin/bash"
fi

sleep 2
;;

2)

read -p "Username to delete: " deluser

if id "$deluser" >/dev/null 2>&1
then
    userdel -r "$deluser"
    echo "✅ User Removed: $deluser"
else
    echo "❌ User Not Found"
fi

sleep 2
;;

3)
echo "SSH Users:"
cat /etc/passwd | grep "/home" | cut -d: -f1
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
