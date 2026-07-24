#!/bin/bash

ssh_menu() {

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
;;

2)
;;

3)
;;

4)
;;

5)
;;

6)
;;

7)
;;

8)
;;

9)
;;

10)
;;

11)
;;

12)
;;

13)
;;

14)
;;

15)
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
