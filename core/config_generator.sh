generate_tls_config() {

    local SERVER="${SERVER:-${SERVER_DOMAIN:-your-domain.com}}"
    local PORT="${PORT:-443}"
    local HOST="${HOST:-$SERVER}"
    local PATH_WS="${PATH_WS:-/ws}"

    echo "trojan://${PASSWORD}@${SERVER}:${PORT}?security=tls&type=ws&host=${HOST}&path=${PATH_WS}#${NAME}"

}

generate_non_tls_config() {
    :
}

generate_tls_proxy_config() {
    :
}

generate_httpcustom_config() {
    :
}

generate_darktunnel_config() {
    :
}
