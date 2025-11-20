#!/bin/bash

set -e

print() {
    echo -e "\n\e[1m> $1\e[0m"
}

printRed() {
    echo -e "\n\e[1;31m> $1\e[0m"
}

printGreen() {
    echo -e "\n\e[1;32m> $1\e[0m"
}

printYellow() {
    echo -e "\n\e[1;33m> $1\e[0m"
}

errorDetails() {
    printRed "Error Detected!"
    print "Line: **$LINENO**"
    print "Failing Command: **$BASH_COMMAND**"
}

trap errorDetails ERR

### BEGIN CODE

# var

DEV_APPS="build-essential curl wget git software-properties-common gcc"

STANDARD_APPS_STOCK="nano htop zip unzip net-tools nala vlc synaptic"
STANDARD_APPS_GNOME="nano htop zip unzip net-tools gnome-tweaks gnome-shell-extension-manager nala vlc synaptic"

GNOME_CHECK=false
INSTALL_RESTRICTED=false

INSTALL_UBUNTU_RESTRICTED_EXTRAS_FLAG="-ure"
SET_TIME_RTC_ON_FLAG="-rtc1"
SET_TIME_RTC_OFF_FLAG="-rtc0"

HELP_FLAG="-help"
HELP_FLAG_SHORT="-h"

HELP_TEXT="\nQuick Ubuntu-based distro setup script, version 1.2b\n
Created by erentomurcuk\n
I am not responsible of any possible damages that may occur to your system with this script.\n
This is a personal script that I use to quickly set up a new installation.\n
Information about flags:\n
-ure     :  Installs ubuntu-restricted-extras as well.\n
-rtc1    :  Sets local time to RTC to avoid time changes with Windows dual-boot.\n
-rtc0    :  Disables local time being set to RTC and exits.\n"

# funcs

checklinux() {
    if [ "$(uname -s)" = "Linux" ]; then
        printGreen "This script is running on Linux. Continuing..."
    else
        printRed "It seems like you are not running this script on Linux."
        print "You are running: $(uname -s)"
        
        read -r -p "Are you sure that you want to continue? (y/n) " response
        
        response=${response,,} 
        
        if [[ "$response" =~ ^(yes|y)$ ]]; then
            printYellow "User confirmed continuation. Proceeding..."
        else
            printRed "Execution cancelled by user. Exiting."
            exit 1
        fi
    fi
}

checkgnome() {
    if ps aux | grep '[g]nome-session' > /dev/null; then
        printGreen "GNOME session detected."
        GNOME_CHECK=true
        print "Set to GNOME install list."
    else
        printYellow "GNOME session NOT detected."
        GNOME_CHECK=false
        print "Reverted to stock install list."
    fi      
}

systemupdate() {
    print "Updating repositories and upgrading packages."
    sudo apt update > /dev/null 2>&1
    sudo apt upgrade -y > /dev/null 2>&1
}

installdev() {
    print "Installing dev applications."
    sudo apt install -y $DEV_APPS > /dev/null 2>&1
}

installapps() {
    if [ "$GNOME_CHECK" = true ]; then
        print "Installing standard apps + apps for GNOME."
        sudo apt install -y $STANDARD_APPS_GNOME > /dev/null 2>&1
    else
        print "Installing standard apps."
        sudo apt install -y $STANDARD_APPS_STOCK > /dev/null 2>&1
    fi
}

cleanupAndAutoremove() {
    printGreen "Cleaning up unnecessary packages."
    sudo apt autoremove -y > /dev/null 2>&1
}

installNautilusAdmin() {
    if [ "$GNOME_CHECK" = true ]; then
        if dpkg -s nautilus 2>/dev/null | grep -q 'Status: install'; then
            printYellow "Nautilus detected. Installing nautilus-admin extension."
            sudo apt install -y nautilus-admin > /dev/null 2>&1
        else
            printYellow "Nautilus not found. Skipping nautilus-admin installation."
        fi
    fi
}

installUbuntuRestrictedExtras() {
    if [ "$INSTALL_RESTRICTED" = true ]; then
        printYellow "Installing Ubuntu Restricted Extras. (Requires Manual EULA Acceptance!)"
        sudo apt install -y ubuntu-restricted-extras > /dev/null 2>&1
    fi
}

setRTCtime() {
    printGreen "Time set as RTC (For Windows Dual-boot compatibility)"
    timedatectl set-local-rtc 1
}

revertsetRTCtime() {
    printGreen "RTC time setting disabled"
    timedatectl set-local-rtc 0
}


for arg in "$@"; do
    if [ "$arg" = "$INSTALL_UBUNTU_RESTRICTED_EXTRAS_FLAG" ]; then
        INSTALL_RESTRICTED=true
        print "Restricted Extras & MS Core Fonts will be installed."
    fi
    
    if [ "$arg" = "$SET_TIME_RTC_ON_FLAG" ]; then
        print "Local time will be set as RTC to avoid time issues."
        setRTCtime
    fi

    if [ "$arg" = "$SET_TIME_RTC_OFF_FLAG" ]; then
        print "Disabling setting local time to RTC. Exiting."
        revertsetRTCtime
        exit 0
    fi

    if [[ "$arg" = "$HELP_FLAG" || "$arg" = "$HELP_FLAG_SHORT" ]]; then
        echo -e "$HELP_TEXT"
        exit 0
    fi
done

# main

checklinux

systemupdate

checkgnome

installapps
installdev

installNautilusAdmin
installUbuntuRestrictedExtras

cleanupAndAutoremove

printGreen "Script Complete"

### END CODE

trap - ERR
exit 0