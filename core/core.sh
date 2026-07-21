#!/bin/bash

# =====================================
# MehboobXT Core Helper
# Version: 1.0.0
# =====================================

PANEL_DIR="/etc/mehboobxt"
LOG_FILE="$PANEL_DIR/panel.log"


create_dirs(){

mkdir -p "$PANEL_DIR"
mkdir -p "$PANEL_DIR/backups"

}


log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

panel_log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

check_root() {

if [ "$EUID" -ne 0 ]
then

echo "❌ Run as root"

exit 1

fi

}


panel_version(){

echo "MehboobXT Panel Version 1.0.0"

}

create_dirs
