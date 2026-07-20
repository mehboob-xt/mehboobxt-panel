#!/bin/bash

update_panel(){

clear

echo "=========================="
echo "🔄 MehboobXT Panel Update"
echo "=========================="

cd /opt/mehboobxt-panel

echo "Checking updates..."

git pull

echo ""
echo "Panel Updated ✅"

echo ""
read -p "Press Enter to Back"

}
