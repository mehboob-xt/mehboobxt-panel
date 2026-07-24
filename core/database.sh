#!/bin/bash

db_exists() {

    local FILE="$1"

    [ -f "$FILE" ]

}

db_add() {

    local FILE="$1"
    local DATA="$2"

    grep -q "^$(echo "$DATA" | cut -d'|' -f1)|" "$FILE" && return 1

echo "$DATA" >> "$FILE" || return 1

return 0

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

    sed -i "/^$QUERY|/d" "$FILE" || return 1

return 0

}

db_update() {

    local FILE="$1"
    local QUERY="$2"
    local DATA="$3"

    sed -i "/^$QUERY|/d" "$FILE" || return 1

echo "$DATA" >> "$FILE" || return 1

return 0

}

db_backup() {

    local FILE="$1"
    local DEST="$2"

    cp "$FILE" "$DEST" || return 1

return 0

}

db_restore() {

    local SRC="$1"
    local DEST="$2"

    cp "$SRC" "$DEST" || return 1

return 0

}
db_read() {

    local FILE="$1"
    local QUERY="$2"

    grep -m1 "^$QUERY|" "$FILE"

}

db_get_field() {

    local FILE="$1"
    local QUERY="$2"
    local FIELD="$3"

    db_read "$FILE" "$QUERY" | cut -d'|' -f"$FIELD"

}

db_count() {

    local FILE="$1"

    wc -l < "$FILE"

}

db_empty() {

    local FILE="$1"

    [ ! -s "$FILE" ]

}

db_list() {

    local FILE="$1"

    cat "$FILE"

}
