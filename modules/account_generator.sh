#!/bin/bash

account_generator(){

clear

echo "=========================="
echo "👤 MehboobXT Account Generator"
echo "=========================="

mkdir -p data

username="user$(date +%s)"
password=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 8)

read -p "Enter Expiry Days: " days

expiry=$(date -d "+$days days" +"%Y-%m-%d")

echo ""
echo "Account Created ✅"
echo "Username: $username"
echo "Password: $password"
echo "Expiry: $expiry"

echo "$username|$password|$expiry" >> data/accounts.db

echo ""
read -p "Press Enter to Back"

}
