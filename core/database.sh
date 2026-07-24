#!/bin/bash

db_exists() {

    local FILE="$1"

    [ -f "$FILE" ]

}

db_add() {

    local FILE="$1"
    local DATA="$2"

    echo "$DATA" >> "$FILE"

}

db_find() {

    local FILE="$1"
    local QUERY="$2"

    grep -m1 "^$QUERY|" "$FILE"

}

db_search() {

    local FILE="$1"
    local QUERY="$2"

    grep -i "$QUERY" "$FILE"

}

db_delete() {

    local FILE="$1"
    local QUERY="$2"

    sed -i "/^$QUERY|/d" "$FILE"

}

db_update() {

    local FILE="$1"
    local QUERY="$2"
    local DATA="$3"

    sed -i "/^$QUERY|/d" "$FILE"

    echo "$DATA" >> "$FILE"

}

db_backup() {

    local FILE="$1"
    local DEST="$2"

    cp "$FILE" "$DEST"

}

db_restore() {

    local SRC="$1"
    local DEST="$2"

    cp "$SRC" "$DEST"

}
