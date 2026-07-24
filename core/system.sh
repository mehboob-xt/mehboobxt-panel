#!/bin/bash

# ===================================
# MehboobXT System Helper
# Linux System Operations
# ===================================
system_user_exists() {

    local USER="$1"

    id "$USER" >/dev/null 2>&1

}

system_create_user() {

    local USER="$1"
    local PASS="$2"
    local EXPIRY="$3"

    useradd \
        -e "$EXPIRY" \
        -M \
        -s /usr/sbin/nologin \
        "$USER" || return 1

    echo "$USER:$PASS" | chpasswd || return 1

return 0

}

system_delete_user() {

    local USER="$1"

    userdel -f "$USER"

}

system_change_password() {

    local USER="$1"
    local PASS="$2"

    echo "$USER:$PASS" | chpasswd

}

system_lock_user() {

    local USER="$1"

    passwd -l "$USER"

}

system_unlock_user() {

    local USER="$1"

    passwd -u "$USER"

}

system_rename_user() {

    local OLDUSER="$1"
    local NEWUSER="$2"

    usermod -l "$NEWUSER" "$OLDUSER"

}

system_set_expiry() {

    local USER="$1"
    local EXPIRY="$2"

    usermod -e "$EXPIRY" "$USER"

}

system_online_users() {

    who

}
