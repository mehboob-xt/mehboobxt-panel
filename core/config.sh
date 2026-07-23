#!/bin/bash

CONFIG_FILE="/etc/mehboobxt/panel.conf"

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Configuration file missing!"
    exit 1
fi
