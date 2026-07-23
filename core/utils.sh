#!/bin/bash

pause() {
    echo
    read -rp "Press Enter to continue..."
}

line() {
    echo "--------------------------------------"
}

header() {
    clear
    banner
    line
}
