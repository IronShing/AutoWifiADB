param(
  [string]$Serial = $null,
  [switch]$UseEmulator
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Resolve adb path (prefer script folder)
$adb = Join-Path $PSScriptRoot 'adb.exe'
if (-not (Test-Path $adb)) { $adb = 'adb.exe' }

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
Start-Sleep -Seconds 1

Write-Host ("[*] Connecting to {0}:{1} ..." -f $phone_ip, $port)
& $adb connect ("{0}:{1}" -f $phone_ip, $port)

Write-Host "`n[*] Current adb devices:"
& $adb devices -l

Write-Host ("`n[OK] Done. To reconnect later:`n    {0} connect {1}:{2}" -f $adb, $phone_ip, $port)
