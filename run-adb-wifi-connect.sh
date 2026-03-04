#!/usr/bin/env bash
# Launch the adb_wifi_connect.sh script.
# Place this file alongside adb_wifi_connect.sh or in ~/Downloads/platform-tools/

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/adb_wifi_connect.sh"

if [[ ! -f "$SCRIPT" ]]; then
    echo "[!] Could not find \"$SCRIPT\""
    echo "    Make sure adb_wifi_connect.sh is in the same directory as this launcher."
    exit 1
fi

bash "$SCRIPT" "$@"
