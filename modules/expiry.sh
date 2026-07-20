#!/bin/bash

expiry_menu(){

clear

echo "=========================="
echo "⏳ MehboobXT Expiry Manager"
echo "=========================="

if [ ! -f data/accounts.db ]; then
    echo "No accounts found"
else
    echo ""
    echo "Checking Accounts..."
    echo ""

    today=$(date +%Y-%m-%d)

    while IFS="|" read -r username password expiry
    do
        if [[ "$expiry" < "$today" ]]; then
            echo "❌ Expired: $username ($expiry)"
        else
            echo "✅ Active: $username ($expiry)"
        fi
    done < data/accounts.db
fi

echo ""
read -p "Press Enter to Back"

}
