# AutoWifiADB

> **Automatically connect to Android devices over Wi-Fi using ADB**

A simple, user-friendly Windows tool that automatically switches your Android device from USB debugging to wireless ADB debugging with just one click.

---

## Features

- **One-Click Setup** - Just double-click and go!
- **Auto-Downloads Platform Tools** - No manual ADB installation needed!
- **Automatic IP Detection** - No manual IP address entry needed
- **Multiple Device Support** - Works with physical devices and emulators
- **Smart ADB Detection** - Automatically finds or downloads `adb.exe`
- **Version Checking** - Displays current platform tools version
- **Error Handling** - Clear error messages guide you when something goes wrong
- **Desktop Friendly** - Simple CMD launcher for easy access

---

## Prerequisites

- **Windows** with PowerShell 5.0 or later
- **Internet connection** (for automatic platform tools download, if needed)
- **Android device** with:
  - USB Debugging enabled
  - Connected to the same Wi-Fi network as your computer
  - Initially connected via USB cable

**Note:** Android Platform Tools (ADB) will be automatically downloaded if not found!

---

## Installation

### Super Simple Setup (Recommended)

1. **Download the script**
   - Download `adb_wifi_connect.ps1` and `Run-ADB-WiFi-Connect.cmd`

2. **Place the files**
   - Put both files in any folder (e.g., `Downloads`, `Documents`, or Desktop)

3. **Run it!**
   - Double-click `Run-ADB-WiFi-Connect.cmd`
   - Platform tools will auto-download on first run if needed

That's it! The script handles everything else automatically.

### Option 2: Use Existing Platform Tools

If you already have Platform Tools installed:

1. **Place the script with your platform tools**
   - Copy `adb_wifi_connect.ps1` to your existing `platform-tools` folder
   - Example: `C:\Users\YourName\Downloads\platform-tools\`

2. **Run the PowerShell script directly:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File adb_wifi_connect.ps1
   ```

The script will automatically detect and use your existing ADB installation.

---

## Usage

### Basic Usage

1. **Connect your Android device via USB**
2. **Ensure Wi-Fi is enabled** on your device
3. **Double-click** `Run-ADB-WiFi-Connect.cmd`
4. **Unplug the USB cable** when prompted

The script will:
- Detect your device
- Find your phone's Wi-Fi IP address
- Switch ADB to TCP/IP mode
- Connect wirelessly

### Advanced Usage

#### Specify a Device Serial

If you have multiple devices connected:

```cmd
Run-ADB-WiFi-Connect.cmd -Serial <DEVICE_SERIAL>
```

Or run the PowerShell script directly:

```powershell
powershell -ExecutionPolicy Bypass -File adb_wifi_connect.ps1 -Serial ABC123XYZ
```

#### Connect to Emulator

```cmd
Run-ADB-WiFi-Connect.cmd -UseEmulator
```

Or:

```powershell
powershell -ExecutionPolicy Bypass -File adb_wifi_connect.ps1 -UseEmulator
```

#### Reconnect Later

After the initial setup, you can reconnect without USB:

```cmd
adb connect <PHONE_IP>:5555
```

The script displays the reconnect command at the end.

---

## How It Works

1. **Platform Tools Check** - Checks for ADB, downloads if missing
2. **Version Check** - Displays current ADB version (can be skipped with `-SkipUpdate`)
3. **Device Detection** - Checks for a connected USB device
4. **IP Discovery** - Queries the device's Wi-Fi IP address via `ip` commands
5. **TCP/IP Switch** - Runs `adb tcpip 5555` to enable wireless debugging
6. **Connection** - Connects to the device wirelessly via `adb connect`

---

## Troubleshooting

### "No matching device" Error

**Cause**: No USB device detected

**Solutions**:
- Ensure USB debugging is enabled on your device
- Try a different USB cable or port
- Run `adb devices` manually to verify detection
- If multiple devices, use `-Serial <id>` flag

### "Could not determine Wi-Fi IP" Error

**Cause**: Device Wi-Fi is off or not connected

**Solutions**:
- Enable Wi-Fi on your Android device
- Connect to a Wi-Fi network
- Ensure the network allows device-to-device communication

### "Execution Policy" Error

**Cause**: PowerShell script execution is restricted

**Solutions**:
- Use the provided `.cmd` launcher (it bypasses this automatically)
- Or run manually:
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
  ```

### Connection Drops

**Cause**: Wi-Fi network changed or device went to sleep

**Solutions**:
- Reconnect using the command displayed at the end
- Re-run the script with USB connected
- Keep your device awake during initial connection

### Platform Tools Download Fails

**Cause**: No internet connection or firewall blocking

**Solutions**:
- Check your internet connection
- Download manually from [Google](https://developer.android.com/tools/releases/platform-tools)
- Extract to script folder or `Downloads\platform-tools`
- Check firewall/antivirus settings

---

## File Structure

```
AutoWifiADB/
├── adb_wifi_connect.ps1      # Main PowerShell script
├── Run-ADB-WiFi-Connect.cmd  # Desktop-friendly launcher
└── README.md                  # This file
```

---

## Parameters Reference

### PowerShell Script Parameters

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `-Serial` | String | Specify device by serial number | `-Serial ABC123XYZ` |
| `-UseEmulator` | Switch | Connect to an emulator instead of physical device | `-UseEmulator` |
| `-SkipUpdate` | Switch | Skip version checking for faster execution | `-SkipUpdate` |

---

## Requirements Details

### Android Device Settings

1. **Enable Developer Options**
   - Go to Settings > About Phone
   - Tap "Build Number" 7 times

2. **Enable USB Debugging**
   - Go to Settings > Developer Options
   - Enable "USB Debugging"

3. **Wi-Fi Connection**
   - Connect to the same Wi-Fi network as your computer
   - Some corporate/public networks may block device-to-device communication

---

## Auto-Download Feature

The script intelligently manages Android Platform Tools:

### Download Priority

1. **Script Directory** - Checks for `platform-tools` folder next to the script
2. **Downloads Folder** - Checks `%USERPROFILE%\Downloads\platform-tools`
3. **Auto-Download** - Downloads latest platform tools from Google if not found
4. **System PATH** - Falls back to system-installed ADB

### First Run

On first run without existing platform tools:
- Downloads latest version from Google (~10MB)
- Extracts automatically to `platform-tools` subfolder
- Ready to use immediately

### Subsequent Runs

- Displays current ADB version
- Uses existing installation
- Use `-SkipUpdate` flag to skip version check for faster execution

### Manual Platform Tools Location

If you prefer a specific location, the CMD launcher can be edited to point to:
```
%USERPROFILE%\Downloads\platform-tools\
```

Example: `C:\Users\YourName\Downloads\platform-tools\`

Edit the `SCRIPT` variable in `Run-ADB-WiFi-Connect.cmd` to change the location.

---

## Security Note

Wireless ADB debugging opens port 5555 on your device. Only use this on trusted networks. To disable wireless debugging:

```cmd
adb usb
```

Or reboot your device.

---

## Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest features
- Submit pull requests

---

## License

This project is provided as-is for personal and commercial use.

---

## Credits

Developed to simplify Android wireless debugging workflow for developers, testers, and enthusiasts.

---

## Support

For issues or questions, please open an issue on the GitHub repository.

**Happy Wireless Debugging!**
