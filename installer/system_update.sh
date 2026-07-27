#!/bin/bash

set -e

source "$(dirname "$0")/../core/config.sh"
source "$(dirname "$0")/../core/logger.sh"

info "Updating system packages..."

export DEBIAN_FRONTEND=noninteractive

apt-get update -y

apt-get upgrade -y

apt-get autoremove -y

apt-get autoclean -y

success "System updated successfully."

exit 0
