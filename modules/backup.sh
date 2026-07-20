#!/bin/bash

backup_menu(){

while true
do

clear

echo "=========================="
echo "💾 MehboobXT Backup System"
echo "=========================="

echo "1. Create Backup"
echo "2. List Backup"
echo "3. Restore Backup"
echo "4. Delete Backup"
echo "5. Back"

echo ""

read -p "Select Option: " backupopt

case $backupopt in

1)
echo "Creating Backup..."

backup_name="mehboobxt-backup-$(date +%Y-%m-%d).tar.gz"

tar -czf /root/$backup_name /opt/mehboobxt-panel 2>/dev/null

echo "Backup Created: $backup_name"
sleep 3
;;

2)
echo "Backup List:"
ls -lh /root/*backup*.tar.gz
sleep 3
;;

3)
echo "Restore Backup"
echo "Restore function ready soon"
sleep 3
;;

4)
echo "Delete Backup"
echo "Delete function ready soon"
sleep 3
;;

5)
break
;;

*)
echo "Invalid Option"
sleep 2
;;

esac

done

}
