#!/bin/bash

set -e

COMPANYCODE="$env:$companyCode"
DMG_URL="https://cloudgz.gravityzone.bitdefender.com/Packages/MAC/0/$COMPANYCODE/setup_downloader.dmg"
DMG_PATH="/var/root/setup_downloader.dmg"
MOUNT_POINT="/Volumes/Endpoint for MAC"
APP_NAME="SetupDownloader.app/Contents/MacOS/SetupDownloader"
INSTALL_PATH="/Applications/Bitdefender"

if [[ -e "$INSTALL_PATH" ]]; then
    printf "BitDefender is Already Installed!"
    exit 0
else
    printf "Downloading $DMG_PATH...\n"
    curl -L -o "$DMG_PATH" "$DMG_URL"

    printf "Mounting $DMG_PATH...\n"
    hdiutil attach "$DMG_PATH" -nobrowse -quiet
    if [ $? -ne 0 ]; then
        printf "[Error]: Failed to Mount '$DMG_PATH'\n"
        exit 1
    fi

    printf "Launching '$APP_NAME' Please Enter an Administrator Username and Password During the Install!\n"
    open -a "$MOUNT_POINT/$APP_NAME"

    INSTALLED = "0"
    while [$INSTALLED == "1"]; do
        sleep 5
        if [[ -e "$INSTALL_PATH" ]]; then
            INSTALLED = "1"
        fi
    done
fi