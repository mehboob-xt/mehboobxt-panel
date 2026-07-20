#!/bin/bash

update_menu(){

clear

echo "=========================="
echo "🔄 MehboobXT Panel Update"
echo "=========================="

echo ""
echo "Checking Updates..."

cd /opt/mehboobxt-panel

git fetch

git status

echo ""
read -p "Update Panel Now? (y/n): " update

case $update in

y|Y)
echo "Updating Panel..."
git pull
echo "Update Complete ✅"
;;

n|N)
echo "Update Cancelled"
;;

*)
echo "Invalid Option"
;;

esac

sleep 3

}
