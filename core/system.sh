#!/bin/bash

source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/logger.sh"

system_hostname() {
    hostname
}

system_os() {
    source /etc/os-release
    echo "$PRETTY_NAME"
}

system_kernel() {
    uname -r
}

system_arch() {
    uname -m
}

system_uptime() {
    uptime -p
}

system_ip() {
    hostname -I | awk '{print $1}'
}

system_ram() {
    free -h | awk '/Mem:/ {print $3 "/" $2}'
}

system_swap() {
    free -h | awk '/Swap:/ {print $3 "/" $2}'
}

system_disk() {
    df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}'
}

system_cpu() {
    grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs
}

cpu_cores() {
    nproc
}

load_average() {
    uptime | awk -F'load average:' '{print $2}'
}

network_online() {
    ping -c1 -W2 1.1.1.1 >/dev/null 2>&1
}

system_summary() {

    echo "Hostname : $(system_hostname)"
    echo "OS      
