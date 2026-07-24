#!/bin/bash

header() {

    clear

    echo "=========================================="
    echo "         MehboobXT Panel"
    echo "=========================================="
    echo ""

}

success() {

    echo "[✔] $1"

}

error() {

    echo "[✘] $1"

}

warning() {

    echo "[!] $1"

}

info() {

    echo "[i] $1"

}

pause() {

    echo ""
    read -rp "Press Enter to continue..."

}

confirm() {

    read -rp "$1 (y/N): " CONFIRM

    case "$CONFIRM" in
        y|Y)
            return 0
            ;;
        *)
            return 1
            ;;
    esac

}

loading() {

    echo ""
    echo "Loading..."
    sleep 1

}
