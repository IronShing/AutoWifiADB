#!/usr/bin/env bash
# Launch the adb_wifi_connect.sh script.
# Place this file alongside adb_wifi_connect.sh or in ~/Downloads/platform-tools/

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/adb_wifi_connect.sh"

# On first run, create a desktop shortcut if ~/Desktop exists
DESKTOP_SHORTCUT="$HOME/Desktop/AutoWifiADB.desktop"
if [[ -d "$HOME/Desktop" && ! -e "$DESKTOP_SHORTCUT" ]]; then
    chmod +x "$SCRIPT_DIR/AutoWifiADB.desktop"
    ln -sf "$SCRIPT_DIR/AutoWifiADB.desktop" "$DESKTOP_SHORTCUT"
    chmod +x "$DESKTOP_SHORTCUT"
    echo "[+] Desktop shortcut created."
fi

if [[ ! -f "$SCRIPT" ]]; then
    echo "[!] Could not find \"$SCRIPT\""
    echo "    Make sure adb_wifi_connect.sh is in the same directory as this launcher."
    exit 1
fi

bash "$SCRIPT" "$@"
