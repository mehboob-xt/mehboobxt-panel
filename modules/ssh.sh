#!/bin/bash

ssh_menu(){

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

useradd -m $user
echo "$user:$pass" | chpasswd

echo "✅ SSH User Created: $user"
sleep 2
;;

2)
read -p "Username to delete: " deluser

userdel -r $deluser

echo "✅ User Removed"
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
