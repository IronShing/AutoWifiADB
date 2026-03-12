#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_DIR="$HOME/ADB_Pulled"

SCREENSHOT_PATH="/sdcard/Pictures/Screenshots"
CAMERA_PATH="/sdcard/DCIM/Camera"

# --- Device selection ---
select_device() {
    local devices
    devices=($(adb devices | awk 'NR>1 && $2=="device" {print $1}'))

    if [[ ${#devices[@]} -eq 0 ]]; then
        echo "[!] No devices connected."
        exit 1
    elif [[ ${#devices[@]} -eq 1 ]]; then
        DEVICE="${devices[0]}"
        echo "[*] Using device: $DEVICE"
    else
        echo "[*] Multiple devices found:"
        for i in "${!devices[@]}"; do
            echo "  $((i+1))) ${devices[$i]}"
        done
        read -rp "Select device [1-${#devices[@]}]: " choice
        if [[ "$choice" -ge 1 && "$choice" -le ${#devices[@]} ]] 2>/dev/null; then
            DEVICE="${devices[$((choice-1))]}"
        else
            echo "[!] Invalid selection."
            exit 1
        fi
    fi
    ADB="adb -s $DEVICE"
}

# --- Helper: today's date formats ---
today_screenshot() { date +%Y-%m-%d; }   # Screenshot_2026-02-13-...
today_camera() { date +%Y%m%d; }          # 20260311_...

# --- 1) Get last screenshot ---
get_last_screenshot() {
    echo "[*] Fetching last screenshot..."
    local file
    file=$($ADB shell "ls -t $SCREENSHOT_PATH/ 2>/dev/null | head -1" | tr -d '\r')
    if [[ -z "$file" ]]; then
        echo "[!] No screenshots found."
        return 1
    fi
    mkdir -p "$DEST_DIR/Screenshots"
    echo "[+] Pulling: $file"
    $ADB pull "$SCREENSHOT_PATH/$file" "$DEST_DIR/Screenshots/"
}

# --- 2) Get all screenshots for today ---
get_today_screenshots() {
    local today
    today=$(today_screenshot)
    echo "[*] Fetching all screenshots for $today..."
    local files
    files=$($ADB shell "ls $SCREENSHOT_PATH/ 2>/dev/null | grep 'Screenshot_${today}'" | tr -d '\r')
    if [[ -z "$files" ]]; then
        echo "[!] No screenshots found for today."
        return 1
    fi
    mkdir -p "$DEST_DIR/Screenshots"
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        echo "[+] Pulling: $file"
        $ADB pull "$SCREENSHOT_PATH/$file" "$DEST_DIR/Screenshots/"
    done <<< "$files"
}

# --- 3) Get all images for today ---
get_today_images() {
    local today
    today=$(today_camera)
    echo "[*] Fetching all images for $today..."
    local files
    files=$($ADB shell "ls $CAMERA_PATH/ 2>/dev/null | grep '^${today}_'" | tr -d '\r')
    if [[ -z "$files" ]]; then
        echo "[!] No images found for today."
        return 1
    fi
    mkdir -p "$DEST_DIR/Camera"
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        echo "[+] Pulling: $file"
        $ADB pull "$CAMERA_PATH/$file" "$DEST_DIR/Camera/"
    done <<< "$files"
}

# --- 4) Get last image today ---
get_last_image_today() {
    local today
    today=$(today_camera)
    echo "[*] Fetching last image for $today..."
    local file
    file=$($ADB shell "ls -t $CAMERA_PATH/ 2>/dev/null | grep '^${today}_' | head -1" | tr -d '\r')
    if [[ -z "$file" ]]; then
        echo "[!] No images found for today."
        return 1
    fi
    mkdir -p "$DEST_DIR/Camera"
    echo "[+] Pulling: $file"
    $ADB pull "$CAMERA_PATH/$file" "$DEST_DIR/Camera/"
}

# --- Menu ---
select_device

echo ""
echo "=== ADB Media Pull ==="
echo "  1) Get last screenshot"
echo "  2) Get all screenshots for today"
echo "  3) Get all images for today"
echo "  4) Get last image today"
echo "  5) Exit"
echo ""
read -rp "Choose [1-5]: " opt

case "$opt" in
    1) get_last_screenshot ;;
    2) get_today_screenshots ;;
    3) get_today_images ;;
    4) get_last_image_today ;;
    5) echo "Bye."; exit 0 ;;
    *) echo "[!] Invalid option."; exit 1 ;;
esac
