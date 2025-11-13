#!/bin/bash

set -e

# --- GLOBAL VARIABLES ---

DEV_APPS="build-essential curl wget git software-properties-common gcc"

STANDARD_APPS_STOCK="nano htop zip unzip net-tools nala vlc synaptic"
# MODIFIED: nautilus-admin removed and will be handled by install_nautilus_addons()
STANDARD_APPS_GNOME="nano htop zip unzip net-tools gnome-tweaks gnome-shell-extension-manager nala vlc synaptic nautilus-admin"

HELP_TEXT="Quick Ubuntu-based distro setup script, version 1.1b\n
            Created by erentomurcuk\n
            I am not responsible of any possible damages that may occur to your system with this script.\n
            This is a personal script that I use to quickly set up a new installation.\n
            Information about flags:\n
            -instre  :  Installs ubuntu-restricted-extras as well.\n
            -instfp  :  Installs flatpak.\n
            -setrtc1 :  Sets local time to RTC to avoid time changes with Windows dual-boot.\n
            -setrtc0 :  Disables local time being set to RTC and exits.\n"

GNOME_CHECK=false
INSTALL_RESTRICTED=false
INSTALL_FLATPAK=false

INSTALL_UBUNTU_RESTRICTED_EXTRAS_FLAG="-instre"
SET_TIME_RTC_ON_FLAG="-setrtc1"
SET_TIME_RTC_OFF_FLAG="-setrtc0"
INSTALL_FLATPAK_FLAG="-instfp"

HELP_FLAG="-help"
HELP_FLAG_SHORT="-h"


# --- FUNCTIONS ---

log() {
    echo -e "\n\e[1m--- $1 ---\e[0m"
}

systemupdate() {
    log "Updating package lists and upgrading installed packages"
    sudo apt update
    sudo apt upgrade -y
}

installdev() {
    log "Installing Development Tools"
    sudo apt install -y $DEV_APPS
}

installapps() {
    log "Installing Standard Applications"
    if [ "$GNOME_CHECK" = true ]; then
        sudo apt install -y $STANDARD_APPS_GNOME
    else
        sudo apt install -y $STANDARD_APPS_STOCK
    fi
}

cleanup() {
    log "Cleaning up unnecessary packages"
    sudo apt autoremove -y
}

installubunture() {
    if [ "$INSTALL_RESTRICTED" = true ]; then
        log "Installing Ubuntu Restricted Extras (Requires Manual EULA Acceptance)"
        sudo apt install -y ubuntu-restricted-extras
    fi
}

setRTCtime() {
    log "Time set as RTC (For Windows Dual-boot compatibility)"
    timedatectl set-local-rtc 1
}

revertsetRTCtime() {
    log "RTC time setting disabled"
    timedatectl set-local-rtc 0
}

installFlatpak() {
    if [ "$INSTALL_FLATPAK" = true ]; then
        log "Installing Flatpak and Flathub repository"
        sudo apt install -y flatpak
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        if [ "$GNOME_CHECK" = true ]; then
            # gnome-software-plugin-flatpak is installed here
            sudo apt install -y gnome-software-plugin-flatpak
        fi
    fi
}

install_nautilus_addons() {
    if [ "$GNOME_CHECK" = true ]; then
        # Check if nautilus is currently installed using dpkg status
        if dpkg -s nautilus 2>/dev/null | grep -q 'Status: install'; then
            log "Nautilus detected. Installing nautilus-admin extension."
            sudo apt install -y nautilus-admin
        else
            log "Nautilus not found. Skipping nautilus-admin installation."
        fi
    fi
}

checkgnome() {
    if ps aux | grep '[g]nome-session' > /dev/null; then
        log "GNOME session detected."
        GNOME_CHECK=true
        log "Set to GNOME install list."
    else
        log "GNOME session NOT detected."
        GNOME_CHECK=false
        log "Reverted to stock install list."
    fi      
}

checkLinux() {
    if [ "$(uname -s)" = "Linux" ]; then
        log "This script is running on Linux. Continuing..."
    else
        log "It seems like you are not running this script on Linux."
        log "You are running: $(uname -s)"
        
        echo ""
        read -r -p "Are you sure that you want to continue? (y/n) " response
        
        response=${response,,} 
        
        if [[ "$response" =~ ^(yes|y)$ ]]; then
            log "User confirmed continuation. Proceeding..."
        else
            log "Execution cancelled by user. Exiting."
            exit 1
        fi
    fi
}

# --- ARGUMENT PARSING ---

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

    if [ "$arg" = "$INSTALL_FLATPAK_FLAG" ]; then
        INSTALL_FLATPAK=true
    fi

    if [[ "$arg" = "$HELP_FLAG" || "$arg" = "$HELP_FLAG_SHORT" ]]; then
        log "$HELP_TEXT"
        exit 0
    fi
done

# --- MAIN EXECUTION ---

checkLinux

systemupdate

checkgnome

installapps
installdev

install_nautilus_addons

installubunture
installFlatpak

cleanup

log "Complete."
exit 1