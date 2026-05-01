#!/bin/bash

read -rp "Enter the full path where you want to install overdrive.sh (e.g. /usr/local/bin/overdrive.sh): " TARGET

if [[ -z "$TARGET" ]]; then
    echo "Install path required."
    exit 1
fi

curl -fsSL "https://raw.githubusercontent.com/alittler/overdrive-amc/main/overdrive.sh" -o "$TARGET" && \
chmod +x "$TARGET" && \
echo "overdrive.sh installed to $TARGET"
