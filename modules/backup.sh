#!/bin/bash

backup_menu(){

clear

echo "=========================="
echo "💾 MehboobXT Backup System"
echo "=========================="

mkdir -p backup

backup_name="backup_$(date +%Y-%m-%d_%H-%M).tar.gz"

tar -czf backup/$backup_name . 

echo ""
echo "Backup Created ✅"
echo "File: backup/$backup_name"

echo ""
read -p "Press Enter to Back"

}
