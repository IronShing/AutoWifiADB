#!/usr/bin/env bash
set -euo pipefail

# AutoWifiADB - Linux version
# Automatically connect to Android devices over Wi-Fi using ADB

# Default parameter values
SERIAL=""
USE_EMULATOR=false
SKIP_UPDATE=false
FORCE_UPDATE=false

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--serial)
            SERIAL="$2"
            shift 2
            ;;
        -e|--emulator)
            USE_EMULATOR=true
            shift
            ;;
        --skip-update)
            SKIP_UPDATE=true
            shift
            ;;
        --force-update)
            FORCE_UPDATE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -s, --serial SERIAL   Specify device by serial number"
            echo "  -e, --emulator        Connect to an emulator instead of physical device"
            echo "      --skip-update     Skip version checking for faster execution"
            echo "      --force-update    Force download and install latest platform tools"
            echo "  -h, --help            Show this help message"
            exit 0
            ;;
        *)
            echo "[!] Unknown option: $1"
            echo "    Use --help for usage information."
            exit 1
            ;;
    esac
done

# Function to download and extract platform tools
install_platform_tools() {
    local target_path="$1"
    local parent_dir
    parent_dir="$(dirname "$target_path")"

    echo "[*] Platform tools not found. Downloading..."

    local platform_tools_url="https://dl.google.com/android/repository/platform-tools-latest-linux.zip"
    local temp_zip="/tmp/platform-tools.zip"

    # Create directory if it doesn't exist
    if [[ ! -d "$parent_dir" ]]; then
        mkdir -p "$parent_dir"
        echo "[+] Created directory: $parent_dir"
    fi

    # Download platform tools
    echo "[*] Downloading from Google servers..."
    if command -v curl &>/dev/null; then
        curl -L -o "$temp_zip" "$platform_tools_url" || {
            echo "[!] Failed to download platform tools with curl"
            echo "    Please download manually from https://developer.android.com/tools/releases/platform-tools"
            exit 1
        }
    elif command -v wget &>/dev/null; then
        wget -O "$temp_zip" "$platform_tools_url" || {
            echo "[!] Failed to download platform tools with wget"
            echo "    Please download manually from https://developer.android.com/tools/releases/platform-tools"
            exit 1
        }
    else
        echo "[!] Neither curl nor wget found. Please install one of them or download platform tools manually."
        echo "    https://developer.android.com/tools/releases/platform-tools"
        exit 1
    fi
    echo "[+] Download complete!"

    # Extract
    echo "[*] Extracting platform tools..."
    if ! command -v unzip &>/dev/null; then
        echo "[!] unzip not found. Please install unzip: sudo apt install unzip"
        rm -f "$temp_zip"
        exit 1
    fi
    unzip -o -q "$temp_zip" -d "$parent_dir"
    echo "[+] Extraction complete!"

    # Make adb executable
    chmod +x "$parent_dir/platform-tools/adb" 2>/dev/null || true

    # Cleanup
    rm -f "$temp_zip"
    echo -e "[+] Platform tools installed successfully!\n"
}

# Function to check and update platform tools
update_platform_tools() {
    local adb_path="$1"
    local platform_tools_dir="$2"
    local force="${3:-false}"

    # Get current version
    local version_output
    version_output=$("$adb_path" version 2>&1 | head -n 1) || true
    if [[ "$version_output" =~ Version[[:space:]]+([0-9]+\.[0-9]+\.[0-9]+) ]]; then
        echo "[*] Current platform tools version: ${BASH_REMATCH[1]}"
    else
        echo "[*] Could not determine current version"
    fi

    if [[ "$force" == "true" ]]; then
        echo "[*] Force update requested. Downloading latest platform tools..."

        # Kill ADB server first to release file locks
        "$adb_path" kill-server &>/dev/null || true
        sleep 0.5

        # Download and install
        install_platform_tools "$platform_tools_dir"
        echo -e "[+] Platform tools updated successfully!\n"
        return 0
    else
        echo -e "[*] Use --force-update to download the latest version.\n"
        return 1
    fi
}

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Determine platform tools path
PLATFORM_TOOLS_DIR="$SCRIPT_DIR/platform-tools"
ADB="$PLATFORM_TOOLS_DIR/adb"

# Check if platform tools exist, if not try other locations or download
if [[ ! -x "$ADB" ]]; then
    # Check in ~/Downloads/platform-tools
    DOWNLOADS_PATH="$HOME/Downloads/platform-tools"
    ADB_DOWNLOADS="$DOWNLOADS_PATH/adb"

    if [[ -x "$ADB_DOWNLOADS" ]]; then
        PLATFORM_TOOLS_DIR="$DOWNLOADS_PATH"
        ADB="$ADB_DOWNLOADS"
        echo "[*] Using platform tools from Downloads folder"
    else
        # Download platform tools to script directory
        install_platform_tools "$PLATFORM_TOOLS_DIR"
        if [[ ! -x "$ADB" ]]; then
            echo "[!] Platform tools installation failed. ADB not found at: $ADB"
            exit 1
        fi
    fi
fi

# Check for updates or force update
if [[ "$FORCE_UPDATE" == "true" ]]; then
    update_platform_tools "$ADB" "$PLATFORM_TOOLS_DIR" "true" || true
    # Reload ADB path after update
    ADB="$PLATFORM_TOOLS_DIR/adb"
elif [[ -x "$ADB" && "$SKIP_UPDATE" == "false" ]]; then
    update_platform_tools "$ADB" "$PLATFORM_TOOLS_DIR" || true
fi

# Fallback to system PATH if still not found
if [[ ! -x "$ADB" ]]; then
    echo "[*] Checking system PATH for adb..."
    if command -v adb &>/dev/null; then
        ADB="adb"
    else
        echo "[!] ADB not found anywhere. Please install Android Platform Tools."
        exit 1
    fi
fi

# Choose transport flags
ADB_ARGS_USB=()
if [[ -n "$SERIAL" ]]; then
    ADB_ARGS_USB=(-s "$SERIAL")
elif [[ "$USE_EMULATOR" == "true" ]]; then
    ADB_ARGS_USB=(-e)
else
    ADB_ARGS_USB=(-d)  # default: USB device
fi

echo "[*] Checking for connected device..."
if ! "$ADB" "${ADB_ARGS_USB[@]}" get-state &>/dev/null; then
    "$ADB" devices -l
    echo "[!] No matching device with flags: ${ADB_ARGS_USB[*]}. Re-run with --serial <id> or --emulator."
    exit 1
fi

DEVICE_SERIAL=$("$ADB" "${ADB_ARGS_USB[@]}" get-serialno | tr -d '[:space:]')
echo "[*] Using device: $DEVICE_SERIAL"

echo "[*] Finding phone's Wi-Fi IP..."
PHONE_IP=""
IP_OUT=$("$ADB" "${ADB_ARGS_USB[@]}" shell ip -o -4 addr show wlan0 2>/dev/null) || true
if [[ "$IP_OUT" =~ inet[[:space:]]+([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/ ]]; then
    PHONE_IP="${BASH_REMATCH[1]}"
fi

if [[ -z "$PHONE_IP" ]]; then
    ROUTE_OUT=$("$ADB" "${ADB_ARGS_USB[@]}" shell ip route get 1.1.1.1 2>/dev/null) || true
    if [[ "$ROUTE_OUT" =~ src[[:space:]]+([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) ]]; then
        PHONE_IP="${BASH_REMATCH[1]}"
    fi
fi

if [[ -z "$PHONE_IP" ]]; then
    echo "[!] Could not determine Wi-Fi IP. Ensure Wi-Fi is ON and connected."
    exit 1
fi

echo "[*] Phone Wi-Fi IP: $PHONE_IP"

PORT=5555
echo "[*] Switching adbd to TCP/IP on port $PORT..."
"$ADB" "${ADB_ARGS_USB[@]}" tcpip "$PORT" >/dev/null
echo "[*] Waiting for device to switch modes..."
sleep 2

echo "[*] Restarting ADB server..."
"$ADB" kill-server >/dev/null 2>&1 || true
sleep 0.5
"$ADB" start-server >/dev/null 2>&1
sleep 0.5

DEVICE_TARGET="$PHONE_IP:$PORT"
echo "[*] Connecting to $DEVICE_TARGET ..."
CONNECT_OUTPUT=$("$ADB" connect "$DEVICE_TARGET" 2>&1)
echo "$CONNECT_OUTPUT"

# Verify connection is not offline
echo "[*] Verifying connection..."
sleep 0.5

RETRY_COUNT=0
MAX_RETRIES=3
CONNECTION_OK=false

while [[ $RETRY_COUNT -lt $MAX_RETRIES && "$CONNECTION_OK" == "false" ]]; do
    DEVICES_OUTPUT=$("$ADB" devices 2>&1)

    if echo "$DEVICES_OUTPUT" | grep -q "$DEVICE_TARGET[[:space:]]*device$"; then
        CONNECTION_OK=true
        echo "[+] Connection verified - device is online!"
        break
    elif echo "$DEVICES_OUTPUT" | grep -q "$DEVICE_TARGET[[:space:]]*offline"; then
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; then
            echo "[!] Device is offline, retrying... (attempt $RETRY_COUNT/$MAX_RETRIES)"
            "$ADB" disconnect "$DEVICE_TARGET" >/dev/null 2>&1 || true
            sleep 1
            "$ADB" connect "$DEVICE_TARGET" >/dev/null 2>&1 || true
            sleep 1
        fi
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; then
            echo "[!] Device not found, retrying... (attempt $RETRY_COUNT/$MAX_RETRIES)"
            sleep 1
            "$ADB" connect "$DEVICE_TARGET" >/dev/null 2>&1 || true
            sleep 1
        fi
    fi
done

echo ""
echo "[*] Current adb devices:"
"$ADB" devices -l

if [[ "$CONNECTION_OK" == "false" ]]; then
    echo ""
    echo "[!] Warning: Device may be offline. Try:"
    echo "    1. Unplug and replug USB cable, then re-run this script"
    echo "    2. Run: adb kill-server && adb connect $DEVICE_TARGET"
    echo "    3. Disable and re-enable USB debugging on your device"
fi

echo ""
echo "[OK] Done. To reconnect later:"
echo "    $ADB connect $PHONE_IP:$PORT"
