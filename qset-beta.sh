#!/bin/bash

set -e

DEV_APPS="build-essential curl wget git software-properties-common gcc"

STANDARD_APPS_STOCK="nano htop zip unzip net-tools nala vlc synaptic"
STANDARD_APPS_GNOME="nano htop zip unzip net-tools gnome-tweaks gnome-shell-extension-manager nala vlc synaptic nautilus-admin"

GNOME_CHECK=false
INSTALL_RESTRICTED=false
INSTALL_FLATPAK=false

INSTALL_UBUNTU_RESTRICTED_EXTRAS_FLAG="-instre"
SET_TIME_RTC_ON_FLAG="-setrtc1"
SET_TIME_RTC_OFF_FLAG="-setrtc0"
INSTALL_FLATPAK_FLAG="-instfp"

for arg in "$@"; do
    if [ "$arg" = "$INSTALL_UBUNTU_RESTRICTED_EXTRAS_FLAG" ]; then
        INSTALL_RESTRICTED=true
        log "You will have to accept the EULA physically."
        log "Restricted Extras & MS Core Fonts will be installed."
    fi
    
    if [ "$arg" = "$SET_TIME_RTC_ON_FLAG" ]; then
    	    log "Local time will be set as RTC to avoid time issues."
            setRTCtime
    fi

    if [ "$arg" = "$SET_TIME_RTC_OFF_FLAG" ]; then
    	    log "Disabled setting local time to RTC. Exiting."
            revertsetRTCtime
            exit 0
    fi

    if [ "$arg" = "$INSTALL_FLATPAK" ]; then
    	    log "Installing Flatpak."
            INSTALL_FLATPAK=true
    fi
done

log() {
    echo -e "\n\e[1m--- $1 ---\e[0m"
}

systemupdate() {
    sudo apt update
    sudo apt upgrade
}

installdev() {
    sudo apt install -y $DEV_APPS
}

installapps() {
    if [ GNOME_CHECK = true ]; then
        sudo apt install -y $STANDARD_APPS_GNOME
    else
        sudo apt install-y $STANDARD_APPS_STOCK
    fi
}

cleanup() {
    sudo apt autoremove -y
}

installubunture() {
    if [ INSTALL_RESTRICTED = true ]; then
        sudo apt install -y ubuntu-restricted-extras
    fi
}

setRTCtime() {
    log "Time set as RTC (not recommended!)"
    timedatectl set-local-rtc 1
}

revertsetRTCtime() {
    log "RTC time disabled"
    timedatectl set-local-rtc 0
}

installFlatpak() {
    sudo apt install flatpak
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    if [ GNOME_CHECK = true ]; then
        sudo apt install -y gnome-software-plugin-flatpak
    fi
}

checkgnome() {
    if ps aux | grep '[g]nome-session' > /dev/null; then
        log "GNOME is running via the ps/grep check."
        GNOME_CHECK=true
        log "Set to GNOME install."

    else
        log "GNOME is NOT running via the ps/grep check."
        GNOME_CHECK=false
        log "Reverted to stock install."
    fi      
}

# main

log "Updating & upgrading via apt."
systemupdate

log "Detecting whether if GNOME is installed."
checkgnome

log "Installing applications"
installapps
installdev

log "Checking extra installations."
installubunture
installFlatpak

log "Cleaning up."
cleanup