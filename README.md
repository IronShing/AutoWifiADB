# AutoWifiADB

> **Automatically connect to Android devices over Wi-Fi using ADB**

A simple, user-friendly Windows tool that automatically switches your Android device from USB debugging to wireless ADB debugging with just one click.

---

## Features

- **One-Click Setup** - Just double-click and go!
- **Automatic IP Detection** - No manual IP address entry needed
- **Multiple Device Support** - Works with physical devices and emulators
- **Smart ADB Detection** - Automatically finds `adb.exe` in the script folder or system PATH
- **Error Handling** - Clear error messages guide you when something goes wrong
- **Desktop Friendly** - Simple CMD launcher for easy access

---

## Prerequisites

- **Windows** with PowerShell 5.0 or later
- **Android Debug Bridge (ADB)** - [Download Platform Tools](https://developer.android.com/tools/releases/platform-tools)
- **Android device** with:
  - USB Debugging enabled
  - Connected to the same Wi-Fi network as your computer
  - Initially connected via USB cable

---

## Installation

### Option 1: Quick Setup (Recommended)

1. **Download Platform Tools**
   - Download Android SDK Platform Tools from [here](https://developer.android.com/tools/releases/platform-tools)
   - Extract to `%USERPROFILE%\Downloads\platform-tools`

2. **Copy the PowerShell Script**
   - Copy `adb_wifi_connect.ps1` to `%USERPROFILE%\Downloads\platform-tools\`

3. **Create Desktop Shortcut**
   - Copy `Run-ADB-WiFi-Connect.cmd` to your Desktop
   - Double-click to run!

### Option 2: Custom Location

1. Place both `adb_wifi_connect.ps1` and `adb.exe` in the same folder
2. Run the PowerShell script directly:
   ```powershell
   powershell -ExecutionPolicy Bypass -File adb_wifi_connect.ps1
   ```

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

1. **Device Detection** - Checks for a connected USB device
2. **IP Discovery** - Queries the device's Wi-Fi IP address via `ip` commands
3. **TCP/IP Switch** - Runs `adb tcpip 5555` to enable wireless debugging
4. **Connection** - Connects to the device wirelessly via `adb connect`

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

## Platform Tools Location

The CMD launcher expects Platform Tools in:
```
%USERPROFILE%\Downloads\platform-tools\
```

Example: `C:\Users\YourName\Downloads\platform-tools\`

If you want to use a different location, edit the `SCRIPT` variable in `Run-ADB-WiFi-Connect.cmd`.

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
