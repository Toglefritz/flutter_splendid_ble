# Flutter Splendid BLE - ESP32 Test Firmware Build Tools
# 
# This Makefile provides convenient commands for building and flashing
# the ESP32 BLE testing firmware using PlatformIO CLI.
#
# Prerequisites:
# - PlatformIO Core CLI installed (pip install platformio)
# - ESP32 development board connected via USB
#
# Usage:
#   make help          - Show available commands
#   make install       - Install PlatformIO if not already installed
#   make build         - Build the firmware
#   make upload        - Build and upload firmware to connected device
#   make monitor       - Start serial monitor
#   make flash         - Build, upload, and start monitoring (recommended)
#   make clean         - Clean build artifacts
#   make list-devices  - List connected serial devices
#   make check-env     - Check if PlatformIO environment is ready

# Configuration
FIRMWARE_DIR = ../firmware/esp32_bluetooth_tester/esp32_bluetooth_tester
PIO = pio
PYTHON = python3
PIP = pip3

# Colors for output
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[1;33m
BLUE = \033[0;34m
NC = \033[0m # No Color

# Function to find PlatformIO project directory
find-pio-project:
	@if [ -f "$(FIRMWARE_DIR)/platformio.ini" ]; then \
		echo "$(GREEN)Found PlatformIO project at: $(FIRMWARE_DIR)$(NC)"; \
	else \
		echo "$(RED)Error: platformio.ini not found at $(FIRMWARE_DIR)$(NC)"; \
		echo "$(YELLOW)Please check the firmware submodule is properly initialized$(NC)"; \
		exit 1; \
	fi

# Default target
.DEFAULT_GOAL := help

# Help target
.PHONY: help
help: ## Show this help message
	@echo "$(BLUE)Flutter Splendid BLE - ESP32 Test Firmware Build Tools$(NC)"
	@echo ""
	@echo "$(YELLOW)Available commands:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(YELLOW)Examples:$(NC)"
	@echo "  make install    # Install PlatformIO CLI"
	@echo "  make flash      # Build, upload, and monitor (most common)"
	@echo "  make upload     # Just build and upload"
	@echo "  make monitor    # Connect to serial monitor"

# Check if PlatformIO is installed
.PHONY: check-pio
check-pio: find-pio-project
	@command -v $(PIO) >/dev/null 2>&1 || { \
		echo "$(RED)Error: PlatformIO CLI not found. Run 'make install' first.$(NC)"; \
		exit 1; \
	}

# Install PlatformIO CLI
.PHONY: install
install: ## Install PlatformIO CLI
	@echo "$(YELLOW)Installing PlatformIO CLI...$(NC)"
	@$(PIP) install platformio
	@echo "$(GREEN)PlatformIO CLI installed successfully!$(NC)"
	@echo "$(BLUE)You may need to restart your terminal or run 'source ~/.bashrc'$(NC)"

# Check environment
.PHONY: check-env
check-env: check-pio ## Check if PlatformIO environment is ready
	@echo "$(YELLOW)Checking PlatformIO environment...$(NC)"
	@cd $(FIRMWARE_DIR) && $(PIO) --version
	@echo "$(GREEN)Environment check passed!$(NC)"

# List connected devices
.PHONY: list-devices
list-devices: check-pio ## List connected serial devices
	@echo "$(YELLOW)Connected serial devices:$(NC)"
	@$(PIO) device list

# Clean build artifacts
.PHONY: clean
clean: check-pio ## Clean build artifacts
	@echo "$(YELLOW)Cleaning build artifacts...$(NC)"
	@cd $(FIRMWARE_DIR) && $(PIO) run --target clean
	@echo "$(GREEN)Clean completed!$(NC)"

# Build firmware
.PHONY: build
build: check-pio ## Build the firmware
	@echo "$(YELLOW)Building ESP32 BLE test firmware...$(NC)"
	@cd $(FIRMWARE_DIR) && $(PIO) run
	@echo "$(GREEN)Build completed successfully!$(NC)"

# Upload firmware
.PHONY: upload
upload: check-pio ## Build and upload firmware to connected device
	@echo "$(YELLOW)Building and uploading ESP32 BLE test firmware...$(NC)"
	@cd $(FIRMWARE_DIR) && $(PIO) run --target upload
	@echo "$(GREEN)Upload completed successfully!$(NC)"
	@echo "$(BLUE)The ESP32 should now be running the BLE test firmware.$(NC)"
	@echo "$(BLUE)Device should advertise as 'SplendidBLE-Tester'$(NC)"

# Start serial monitor
.PHONY: monitor
monitor: check-pio ## Start serial monitor
	@echo "$(YELLOW)Starting serial monitor...$(NC)"
	@echo "$(BLUE)Press Ctrl+C to exit monitor$(NC)"
	@cd $(FIRMWARE_DIR) && $(PIO) device monitor

# Build, upload, and monitor (most convenient command)
.PHONY: flash
flash: check-pio ## Build, upload firmware, and start monitoring (recommended)
	@echo "$(YELLOW)Building and flashing ESP32 BLE test firmware...$(NC)"
	@cd $(FIRMWARE_DIR) && $(PIO) run --target upload --target monitor
	@echo "$(GREEN)Flash and monitor completed!$(NC)"

# Update PlatformIO and libraries
.PHONY: update
update: check-pio ## Update PlatformIO and project libraries
	@echo "$(YELLOW)Updating PlatformIO...$(NC)"
	@$(PIO) upgrade
	@echo "$(YELLOW)Updating project libraries...$(NC)"
	@cd $(FIRMWARE_DIR) && $(PIO) lib update
	@echo "$(GREEN)Update completed!$(NC)"

# Show project information
.PHONY: info
info: check-pio ## Show project information
	@echo "$(YELLOW)ESP32 BLE Test Firmware Project Information:$(NC)"
	@cd $(FIRMWARE_DIR) && $(PIO) project config
	@echo ""
	@echo "$(YELLOW)Available environments:$(NC)"
	@cd $(FIRMWARE_DIR) && $(PIO) project data | grep "env_name"

# Erase flash memory
.PHONY: erase
erase: check-pio ## Erase ESP32 flash memory
	@echo "$(RED)WARNING: This will erase all data on the ESP32!$(NC)"
	@read -p "Are you sure? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	@echo "$(YELLOW)Erasing ESP32 flash memory...$(NC)"
	@cd $(FIRMWARE_DIR) && $(PIO) run --target erase
	@echo "$(GREEN)Flash memory erased!$(NC)"

# Run tests (if any test framework is configured)
.PHONY: test
test: check-pio ## Run firmware tests
	@echo "$(YELLOW)Running firmware tests...$(NC)"
	@cd $(FIRMWARE_DIR) && $(PIO) test
	@echo "$(GREEN)Tests completed!$(NC)"

# Show firmware size information
.PHONY: size
size: check-pio ## Show firmware size information
	@echo "$(YELLOW)Firmware size information:$(NC)"
	@cd $(FIRMWARE_DIR) && $(PIO) run --target size

# Quick setup for new users
.PHONY: setup
setup: install check-env init-submodule ## Complete setup for new users
	@echo "$(GREEN)Setup completed! You can now use 'make flash' to build and upload firmware.$(NC)"

# Initialize git submodule
.PHONY: init-submodule
init-submodule: ## Initialize the firmware git submodule
	@echo "$(YELLOW)Initializing firmware submodule...$(NC)"
	@cd .. && git submodule update --init --recursive
	@echo "$(GREEN)Submodule initialized!$(NC)"

# Development workflow - build and upload on file changes
.PHONY: dev
dev: check-pio ## Development mode - watch for changes and auto-upload
	@echo "$(YELLOW)Starting development mode...$(NC)"
	@echo "$(BLUE)Watching for file changes. Press Ctrl+C to stop.$(NC)"
	@while true; do \
		$(MAKE) upload; \
		echo "$(BLUE)Waiting for file changes...$(NC)"; \
		sleep 5; \
	done

# Backup current firmware
.PHONY: backup
backup: check-pio ## Backup current firmware from ESP32
	@echo "$(YELLOW)Creating firmware backup...$(NC)"
	@mkdir -p backups
	@cd $(FIRMWARE_DIR) && $(PIO) run --target backup
	@echo "$(GREEN)Firmware backup created in backups/ directory$(NC)"

# Show this makefile
.PHONY: show-makefile
show-makefile: ## Display the contents of this Makefile
	@cat $(MAKEFILE_LIST)