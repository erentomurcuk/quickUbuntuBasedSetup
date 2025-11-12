#!/bin/bash

set -e

log() {
    echo -e "\n\e[1m--- $1 ---\e[0m"
}

RESTRICTED_EXTRAS_FLAG="-re"
DUAL_BOOT_WIN_FLAG="-dbwin"

INSTALL_RESTRICTED=false
DUAL_BOOT_WIN=false

for arg in "$@"; do
    if [ "$arg" = "$RESTRICTED_EXTRAS_FLAG" ]; then
        INSTALL_RESTRICTED=true
        log "Optional flag found: Restricted Extras & MS Core Fonts WILL be installed."
    fi
    
    if [ "$arg" = "$DUAL_BOOT_WIN_FLAG" ]; then
    	DUAL_BOOT_WIN=true
    	        log "Optional flag found, local time will be set as RTC to avoid time issues."
    	        timedatectl set-local-rtc 1
    fi
done

log "System Update and Essentials"

sudo apt update
sudo apt install -y build-essential curl wget git software-properties-common

log "Installing Applications"

STANDARD_APPS="nano htop zip unzip net-tools gnome-tweaks gnome-shell-extension-manager nala vlc synaptic nautilus-admin"

sudo apt install -y $STANDARD_APPS

if [ "$INSTALL_RESTRICTED" = true ]; then
    sudo apt install -y ubuntu-restricted-extras
else
    log "Skipping Ubuntu Restricted Extras & MS Core Fonts (Optional flag -re not provided)."
fi

log "Final Clean Up"

sudo apt autoremove -y

log "Setup Complete!"

