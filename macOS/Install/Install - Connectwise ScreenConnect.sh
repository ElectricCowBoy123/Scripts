#!/bin/bash
# pkgutil --pkgs | grep "connectwisecontrol-" | xargs -I {} sudo pkgutil --forget {} && rm -f -r /Applications/connectwisecontrol-1a5d6cc5d5f07e3e.app

build_url(){
    if [[ ! -n "$NINJA_COMPANY_NAME" || ! -n "$NINJA_ORGANIZATION_NAME" || ! -n "$NINJA_LOCATION_NAME" ]]; then
        echo "Failed to Retrieve Ninja RMM Built-in Variables Needed to Generate URL!"
        exit 1
    fi

    PKG_URL=""
    PKG_URL="$PKG_URL/Bin"

    COMPANY=$(echo "$NINJA_COMPANY_NAME" | perl -MURI::Escape -ne 'chomp;print uri_escape($_),"\n"')
    PKG_URL="$PKG_URL/$COMPANY.ClientSetup.pkg?e=Access&y=Guest"

    ORGNAME=$(echo "$NINJA_ORGANIZATION_NAME" | perl -MURI::Escape -ne 'chomp;print uri_escape($_),"\n"')
    PKG_URL="$PKG_URL&c=$ORGNAME"

    SITE=$(echo "$NINJA_LOCATION_NAME" | perl -MURI::Escape -ne 'chomp;print uri_escape($_),"\n"')
    PKG_URL="$PKG_URL&c=$SITE"

    if [[ ! -n "$env:$department" ]]; then
        DEPARTMENT=$(echo "$env:$department" | perl -MURI::Escape -ne 'chomp;print uri_escape($_),"\n"')
        PKG_URL="$PKG_URL&c=$DEPARTMENT"
    fi

    MODEL_NAME=$(system_profiler SPHardwareDataType -detaillevel mini | grep "Model Name" | sed 's/Model Name://' | xargs)
    MODEL_ID=$(system_profiler SPHardwareDataType -detaillevel mini | grep "Model Identifier" | sed 's/Model Identifier://' | xargs)

    if [[ $MODEL_NAME == *"MacBook"* || $MODEL_ID == *"MacBook"* ]]; then
        DEVICE_TYPE="Laptop"
        PKG_URL="$PKG_URL&c=$DEVICE_TYPE"
    else
        DEVICE_TYPE="Workstation"
        PKG_URL="$PKG_URL&c=$DEVICE_TYPE"
    fi

    PKG_URL="$PKG_URL&c=&c=&c=&c="

    echo "Full URL: '$PKG_URL'"
}

check_already_installed(){
    INSTALLED_PACKAGE=$(pkgutil --pkgs | grep "connectwisecontrol-")
    if [[ -n "$INSTALLED_PACKAGE" ]]; then
        echo "Connectwise ScreenConnect is already installed!"
        exit 0
    fi
}

download_pkg(){
    PKG_PATH="/var/root/ScreenConnect.ClientSetup.pkg"
    if [[ -f $PKG_PATH ]]; then
        echo "Connectwise ScreenConnect Package is Already Downloaded! Redownloading..."
        echo ""
        curl -L -o "$PKG_PATH" "$PKG_URL"
        echo ""
    else
        echo "Downloading '$PKG_URL'..."
        echo ""
        curl -L -o "$PKG_PATH" "$PKG_URL"
        echo ""
    fi

    if [[ ! -f $PKG_PATH ]]; then
        echo "Failed to Download Connectwise ScreenConnect!"
        exit 1
    fi
}

install_pkg(){
    echo "Installing application..."
    if installer -pkg "$PKG_PATH" -target /; then
        printf "Exit Code: $?\n"
        echo "Connectwise ScreenConnect Installed Successfully!"
        rm -f "$PKG_PATH"
        exit 0
    else
        printf "Exit Code: $?\n"
        rm -f "$PKG_PATH"
        echo "Installation Failed!"
        exit 1
    fi
}

echo "Checking if ConnectWise is Already Installed..."
check_already_installed

echo "Building URL..."
build_url

echo "Downloading ConnectWise Package..."
download_pkg

echo "Installing Connectwise Package..."
install_pkg