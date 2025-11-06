param(
  [string]$Serial = $null,
  [switch]$UseEmulator,
  [switch]$SkipUpdate,
  [switch]$ForceUpdate
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Function to download and extract platform tools
function Install-PlatformTools {
    param([string]$TargetPath)

    Write-Host "[*] Platform tools not found. Downloading..."

    $platformToolsUrl = "https://dl.google.com/android/repository/platform-tools-latest-windows.zip"
    $tempZip = Join-Path $env:TEMP "platform-tools.zip"
    $parentDir = Split-Path $TargetPath -Parent

    try {
        # Create directory if it doesn't exist
        if (-not (Test-Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
            Write-Host "[+] Created directory: $parentDir"
        }

        # Download platform tools
        Write-Host "[*] Downloading from Google servers..."
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $platformToolsUrl -OutFile $tempZip -UseBasicParsing
        Write-Host "[+] Download complete!"

        # Extract
        Write-Host "[*] Extracting platform tools..."
        Expand-Archive -Path $tempZip -DestinationPath $parentDir -Force
        Write-Host "[+] Extraction complete!"

        # Cleanup
        Remove-Item $tempZip -Force
        Write-Host "[+] Platform tools installed successfully!`n"

    } catch {
        Write-Host "[!] Failed to download platform tools: $_"
        throw "Could not install platform tools. Please download manually from https://developer.android.com/tools/releases/platform-tools"
    }
}

# Function to check and update platform tools
function Update-PlatformTools {
    param(
        [string]$AdbPath,
        [string]$PlatformToolsDir,
        [switch]$Force
    )

    try {
        # Get current version
        $versionOutput = & $AdbPath version 2>&1 | Select-Object -First 1
        if ($versionOutput -match 'Version\s+(\d+\.\d+\.\d+)') {
            $currentVersion = $matches[1]
            Write-Host "[*] Current platform tools version: $currentVersion"
        } else {
            Write-Host "[*] Could not determine current version"
        }

        if ($Force) {
            Write-Host "[*] Force update requested. Downloading latest platform tools..."

            # Kill ADB server first to release file locks
            try {
                & $AdbPath kill-server 2>&1 | Out-Null
                Start-Sleep -Milliseconds 500
            } catch {
                # Ignore errors
            }

            # Download and install
            Install-PlatformTools -TargetPath $PlatformToolsDir
            Write-Host "[+] Platform tools updated successfully!`n"
            return $true
        } else {
            Write-Host "[*] Use -ForceUpdate to download the latest version.`n"
            return $false
        }
    } catch {
        Write-Host "[!] Could not check/update platform tools: $_`n"
        return $false
    }
}

# Determine platform tools path
$platformToolsDir = Join-Path $PSScriptRoot "platform-tools"
$adb = Join-Path $platformToolsDir 'adb.exe'

# Check if platform tools exist, if not download them
if (-not (Test-Path $adb)) {
    $downloadsPath = Join-Path $env:USERPROFILE "Downloads\platform-tools"
    $adbDownloads = Join-Path $downloadsPath 'adb.exe'

    if (Test-Path $adbDownloads) {
        # Use existing platform tools in Downloads
        $platformToolsDir = $downloadsPath
        $adb = $adbDownloads
        Write-Host "[*] Using platform tools from Downloads folder"
    } else {
        # Download platform tools to script directory
        Install-PlatformTools -TargetPath $platformToolsDir
        if (-not (Test-Path $adb)) {
            throw "Platform tools installation failed. ADB not found at: $adb"
        }
    }
}

# Check for updates or force update
if ($ForceUpdate.IsPresent) {
    Update-PlatformTools -AdbPath $adb -PlatformToolsDir $platformToolsDir -Force
    # Reload ADB path after update
    $adb = Join-Path $platformToolsDir 'adb.exe'
} elseif ((Test-Path $adb) -and -not $SkipUpdate.IsPresent) {
    # Platform tools exist, show version
    Update-PlatformTools -AdbPath $adb -PlatformToolsDir $platformToolsDir
}

# Fallback to system PATH if still not found
if (-not (Test-Path $adb)) {
    Write-Host "[*] Checking system PATH for adb.exe..."
    $adb = 'adb.exe'
}

# Choose transport flags
$adbArgsUSB = @()
if ($Serial) { $adbArgsUSB = @('-s', $Serial) }
elseif ($UseEmulator.IsPresent) { $adbArgsUSB = @('-e') }
else { $adbArgsUSB = @('-d') }  # default: USB device

Write-Host "[*] Checking for connected device..."
$null = & $adb @adbArgsUSB get-state 2>$null
if ($LASTEXITCODE -ne 0) {
    & $adb devices -l
    throw "No matching device with flags: $($adbArgsUSB -join ' '). Re-run with -Serial <id> or -UseEmulator."
}

$serial = (& $adb @adbArgsUSB get-serialno).Trim()
Write-Host ("[*] Using device: {0}" -f $serial)

Write-Host "[*] Finding phone's Wi-Fi IP..."
$phone_ip = $null
$ipOut = (& $adb @adbArgsUSB shell ip -o -4 addr show wlan0) -join "`n"
if ($ipOut -match 'inet\s+([0-9.]+)/') { $phone_ip = $matches[1] }
if (-not $phone_ip) {
    $routeOut = (& $adb @adbArgsUSB shell ip route get 1.1.1.1) -join "`n"
    if ($routeOut -match 'src\s+([0-9.]+)') { $phone_ip = $matches[1] }
}
if (-not $phone_ip) { throw "Could not determine Wi-Fi IP. Ensure Wi-Fi is ON and connected." }

Write-Host ("[*] Phone Wi-Fi IP: {0}" -f $phone_ip)

$port = 5555
Write-Host ("[*] Switching adbd to TCP/IP on port {0}..." -f $port)
& $adb @adbArgsUSB tcpip $port | Out-Null
Write-Host "[*] Waiting for device to switch modes..."
Start-Sleep -Seconds 2

Write-Host "[*] Restarting ADB server..."
& $adb kill-server | Out-Null
Start-Sleep -Milliseconds 500
& $adb start-server 2>&1 | Out-Null
Start-Sleep -Milliseconds 500

Write-Host ("[*] Connecting to {0}:{1} ..." -f $phone_ip, $port)
$connectOutput = & $adb connect ("{0}:{1}" -f $phone_ip, $port) 2>&1
Write-Host $connectOutput

# Verify connection is not offline
Write-Host "[*] Verifying connection..."
Start-Sleep -Milliseconds 500

$deviceTarget = "{0}:{1}" -f $phone_ip, $port
$retryCount = 0
$maxRetries = 3
$connectionOk = $false

while ($retryCount -lt $maxRetries -and -not $connectionOk) {
    $devicesOutput = & $adb devices | Out-String

    if ($devicesOutput -match "$deviceTarget\s+device\s") {
        $connectionOk = $true
        Write-Host "[+] Connection verified - device is online!"
        break
    } elseif ($devicesOutput -match "$deviceTarget\s+offline") {
        $retryCount++
        if ($retryCount -lt $maxRetries) {
            Write-Host "[!] Device is offline, retrying... (attempt $retryCount/$maxRetries)"
            & $adb disconnect $deviceTarget | Out-Null
            Start-Sleep -Seconds 1
            & $adb connect $deviceTarget | Out-Null
            Start-Sleep -Seconds 1
        }
    } else {
        $retryCount++
        if ($retryCount -lt $maxRetries) {
            Write-Host "[!] Device not found, retrying... (attempt $retryCount/$maxRetries)"
            Start-Sleep -Seconds 1
            & $adb connect $deviceTarget | Out-Null
            Start-Sleep -Seconds 1
        }
    }
}

Write-Host "`n[*] Current adb devices:"
& $adb devices -l

if (-not $connectionOk) {
    Write-Host "`n[!] Warning: Device may be offline. Try:"
    Write-Host "    1. Unplug and replug USB cable, then re-run this script"
    Write-Host "    2. Run: adb kill-server && adb connect $deviceTarget"
    Write-Host "    3. Disable and re-enable USB debugging on your device"
}

Write-Host ("`n[OK] Done. To reconnect later:`n    {0} connect {1}:{2}" -f $adb, $phone_ip, $port)
