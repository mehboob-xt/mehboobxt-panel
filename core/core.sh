#!/bin/bash

# =====================================
# MehboobXT Core Helper
# Version: 1.0.0
# =====================================


PANEL_DIR="/etc/mehboobxt"
LOG_FILE="$PANEL_DIR/panel.log"


root_check(){

if [ "$EUID" -ne 0 ]
then

echo "❌ Please run as root"
exit 1

fi

}


panel_log(){

mkdir -p "$PANEL_DIR"

echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"

}


panel_info(){

echo ""
echo "=========================="
echo "🚀 MehboobXT Panel"
echo "=========================="
echo "Version : 1.0.0"
echo "Status  : Running"
echo ""

}


create_dirs(){

mkdir -p "$PANEL_DIR"
mkdir -p "$PANEL_DIR/backups"

}


