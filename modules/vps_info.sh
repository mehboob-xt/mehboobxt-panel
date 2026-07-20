#!/bin/bash

vps_info(){
clear

echo "=========================="
echo "🚀 MehboobXT VPS Information"
echo "=========================="

echo ""
echo "Hostname:"
hostname

echo ""
echo "OS:"
lsb_release -d 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME

echo ""
echo "Kernel:"
uname -r

echo ""
echo "CPU:"
lscpu | grep "Model name"

echo ""
echo "RAM:"
free -h

echo ""
echo "Disk:"
df -h /

echo ""
echo "IP Address:"
curl -s ifconfig.me

echo ""
read -p "Press Enter to Back"

}
