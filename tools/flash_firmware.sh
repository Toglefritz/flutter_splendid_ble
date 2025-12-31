#!/bin/bash

# Flutter Splendid BLE - ESP32 Firmware Flash Script
# 
# This script provides a simple way to flash the ESP32 BLE testing firmware
# using PlatformIO CLI. It's an alternative to using the Makefile.
#
# Usage:
#   ./flash_firmware.sh [command]
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

set -e  # Exit on any error

# Configuration
FIRMWARE_DIR="../firmware/esp32_bluetooth_tester/esp32_bluetooth_tester"
PIO_CMD="pio"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_pio() {
    if ! command -v $PIO_CMD &> /dev/null; then
        print_error "PlatformIO CLI not found. Run '$0 install' first."
        exit 1
    fi
    
    if [ ! -f "$FIRMWARE_DIR/platformio.ini" ]; then
        print_error "platformio.ini not found at $FIRMWARE_DIR"
        print_warning "Please check that the firmware submodule is properly initialized:"
        print_info "  git submodule update --init --recursive"
        exit 1
    fi
    
    print_info "Found PlatformIO project at: $FIRMWARE_DIR"
}

show_help() {
    echo -e "${BLUE}Flutter Splendid BLE - ESP32 Firmware Flash Script${NC}"
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $0 [command]"
    echo ""
    echo -e "${YELLOW}Commands:${NC}"
    echo "  install    Install PlatformIO CLI"
    echo "  setup      Complete setup (install + init submodule)"
    echo "  build      Build firmware only"
    echo "  upload     Build and upload firmware"
    echo "  monitor    Start serial monitor"
    echo "  flash      Build, upload, and monitor (default)"
    echo "  clean      Clean build artifacts"
    echo "  devices    List connected devices"
    echo "  help       Show this help"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 install    # Install PlatformIO CLI"
    echo "  $0 flash      # Build, upload, and monitor (most common)"
    echo "  $0 upload     # Just build and upload"
    echo "  $0 monitor    # Connect to serial monitor"
}

install_pio() {
    print_info "Installing PlatformIO CLI..."
    pip3 install platformio
    print_success "PlatformIO CLI installed successfully!"
    print_info "You may need to restart your terminal or run 'source ~/.bashrc'"
}

build_firmware() {
    check_pio
    print_info "Building ESP32 BLE test firmware..."
    cd "$FIRMWARE_DIR"
    $PIO_CMD run
    print_success "Build completed successfully!"
}

upload_firmware() {
    check_pio
    print_info "Building and uploading ESP32 BLE test firmware..."
    cd "$FIRMWARE_DIR"
    $PIO_CMD run --target upload
    print_success "Upload completed successfully!"
    print_info "The ESP32 should now be running the BLE test firmware."
    print_info "Device should advertise as 'SplendidBLE-Tester'"
}

monitor_serial() {
    check_pio
    print_info "Starting serial monitor..."
    print_info "Press Ctrl+C to exit monitor"
    cd "$FIRMWARE_DIR"
    $PIO_CMD device monitor
}

flash_firmware() {
    check_pio
    print_info "Building and flashing ESP32 BLE test firmware..."
    cd "$FIRMWARE_DIR"
    $PIO_CMD run --target upload --target monitor
    print_success "Flash and monitor completed!"
}

clean_build() {
    check_pio
    print_info "Cleaning build artifacts..."
    cd "$FIRMWARE_DIR"
    $PIO_CMD run --target clean
    print_success "Clean completed!"
}

list_devices() {
    check_pio
    print_info "Connected serial devices:"
    $PIO_CMD device list
}

init_submodule() {
    print_info "Initializing firmware submodule..."
    cd ..
    git submodule update --init --recursive
    cd tools
    print_success "Submodule initialized!"
}

setup_complete() {
    install_pio
    check_pio
    init_submodule
    print_success "Setup completed! You can now use '$0 flash' to build and upload firmware."
}

# Main script logic
case "${1:-flash}" in
    "install")
        install_pio
        ;;
    "build")
        build_firmware
        ;;
    "upload")
        upload_firmware
        ;;
    "monitor")
        monitor_serial
        ;;
    "flash")
        flash_firmware
        ;;
    "clean")
        clean_build
        ;;
    "devices")
        list_devices
        ;;
    "setup")
        setup_complete
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac