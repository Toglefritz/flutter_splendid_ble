# Flutter Splendid BLE - ESP32 Firmware Flash Script (PowerShell)
# 
# This PowerShell script provides a simple way to flash the ESP32 BLE testing firmware
# using PlatformIO CLI on Windows systems.
#
# Usage:
#   .\flash_firmware.ps1 [command]
#
# Commands:
#   install    - Install PlatformIO CLI
#   build      - Build firmware only
#   upload     - Build and upload firmware
#   monitor    - Start serial monitor
#   flash      - Build, upload, and monitor (default)
#   clean      - Clean build artifacts
#   devices    - List connected devices
#   help       - Show this help

param(
    [string]$Command = "flash"
)

# Configuration
$FirmwareDir = "..\firmware\esp32_bluetooth_tester\esp32_bluetooth_tester"
$PioCmd = "pio"

# Helper functions
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Test-PlatformIO {
    try {
        & $PioCmd --version | Out-Null
    }
    catch {
        Write-Error "PlatformIO CLI not found. Run '.\flash_firmware.ps1 install' first."
        exit 1
    }
    
    if (-not (Test-Path "$FirmwareDir\platformio.ini")) {
        Write-Error "platformio.ini not found at $FirmwareDir"
        Write-Warning "Please check that the firmware submodule is properly initialized:"
        Write-Info "  git submodule update --init --recursive"
        exit 1
    }
    
    Write-Info "Found PlatformIO project at: $FirmwareDir"
    return $true
}

function Show-Help {
    Write-Host "Flutter Splendid BLE - ESP32 Firmware Flash Script" -ForegroundColor Blue
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\flash_firmware.ps1 [command]"
    Write-Host ""
    Write-Host "Commands:" -ForegroundColor Yellow
    Write-Host "  install    Install PlatformIO CLI"
    Write-Host "  setup      Complete setup (install + init submodule)"
    Write-Host "  build      Build firmware only"
    Write-Host "  upload     Build and upload firmware"
    Write-Host "  monitor    Start serial monitor"
    Write-Host "  flash      Build, upload, and monitor (default)"
    Write-Host "  clean      Clean build artifacts"
    Write-Host "  devices    List connected devices"
    Write-Host "  help       Show this help"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  .\flash_firmware.ps1 install    # Install PlatformIO CLI"
    Write-Host "  .\flash_firmware.ps1 flash      # Build, upload, and monitor (most common)"
    Write-Host "  .\flash_firmware.ps1 upload     # Just build and upload"
    Write-Host "  .\flash_firmware.ps1 monitor    # Connect to serial monitor"
}

function Install-PlatformIO {
    Write-Info "Installing PlatformIO CLI..."
    try {
        pip install platformio
        Write-Success "PlatformIO CLI installed successfully!"
        Write-Info "You may need to restart your terminal or PowerShell session"
    }
    catch {
        Write-Error "Failed to install PlatformIO CLI. Make sure Python and pip are installed."
        exit 1
    }
}

function Build-Firmware {
    Test-PlatformIO
    Write-Info "Building ESP32 BLE test firmware..."
    Push-Location $FirmwareDir
    try {
        & $PioCmd run
        Write-Success "Build completed successfully!"
    }
    catch {
        Write-Error "Build failed. Check the error messages above."
        exit 1
    }
    finally {
        Pop-Location
    }
}

function Upload-Firmware {
    Test-PlatformIO
    Write-Info "Building and uploading ESP32 BLE test firmware..."
    Push-Location $FirmwareDir
    try {
        & $PioCmd run --target upload
        Write-Success "Upload completed successfully!"
        Write-Info "The ESP32 should now be running the BLE test firmware."
        Write-Info "Device should advertise as 'SplendidBLE-Tester'"
    }
    catch {
        Write-Error "Upload failed. Check the error messages above."
        exit 1
    }
    finally {
        Pop-Location
    }
}

function Start-Monitor {
    Test-PlatformIO
    Write-Info "Starting serial monitor..."
    Write-Info "Press Ctrl+C to exit monitor"
    Push-Location $FirmwareDir
    try {
        & $PioCmd device monitor
    }
    catch {
        Write-Error "Monitor failed. Check if device is connected."
        exit 1
    }
    finally {
        Pop-Location
    }
}

function Flash-Firmware {
    Test-PlatformIO
    Write-Info "Building and flashing ESP32 BLE test firmware..."
    Push-Location $FirmwareDir
    try {
        & $PioCmd run --target upload --target monitor
        Write-Success "Flash and monitor completed!"
    }
    catch {
        Write-Error "Flash failed. Check the error messages above."
        exit 1
    }
    finally {
        Pop-Location
    }
}

function Clean-Build {
    Test-PlatformIO
    Write-Info "Cleaning build artifacts..."
    Push-Location $FirmwareDir
    try {
        & $PioCmd run --target clean
        Write-Success "Clean completed!"
    }
    catch {
        Write-Error "Clean failed. Check the error messages above."
        exit 1
    }
    finally {
        Pop-Location
    }
}

function Get-Devices {
    Test-PlatformIO
    Write-Info "Connected serial devices:"
    try {
        & $PioCmd device list
    }
    catch {
        Write-Error "Failed to list devices."
        exit 1
    }
}

function Initialize-Submodule {
    Write-Info "Initializing firmware submodule..."
    try {
        Set-Location ..
        git submodule update --init --recursive
        Set-Location tools
        Write-Success "Submodule initialized!"
    }
    catch {
        Write-Error "Failed to initialize submodule. Make sure git is installed."
        exit 1
    }
}

function Complete-Setup {
    Install-PlatformIO
    Test-PlatformIO
    Initialize-Submodule
    Write-Success "Setup completed! You can now use '.\flash_firmware.ps1 flash' to build and upload firmware."
}

# Main script logic
switch ($Command.ToLower()) {
    "install" {
        Install-PlatformIO
    }
    "build" {
        Build-Firmware
    }
    "upload" {
        Upload-Firmware
    }
    "monitor" {
        Start-Monitor
    }
    "flash" {
        Flash-Firmware
    }
    "clean" {
        Clean-Build
    }
    "devices" {
        Get-Devices
    }
    "setup" {
        Complete-Setup
    }
    "help" {
        Show-Help
    }
    default {
        Write-Error "Unknown command: $Command"
        Write-Host ""
        Show-Help
        exit 1
    }
}