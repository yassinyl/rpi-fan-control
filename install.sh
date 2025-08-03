#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
INSTALL_DIR="/home/pi/rpi-fan-control"

echo "--- Starting Full Installation for RPi Fan Control ---"

# 1. Update package list
echo "[1/5] Updating package list..."
sudo apt update

# 2. Install all required packages
echo "[2/5] Installing core dependencies (python3, git, python3-rpi.gpio, python3-psutil)..."
sudo apt install -y python3 git python3-rpi.gpio python3-psutil

# 3. Create installation directory and copy project files
echo "[3/5] Copying project files to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
# Using the current script's directory to find the files
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
sudo cp "$SCRIPT_DIR/pwm-fan-control.py" "$INSTALL_DIR/"
sudo cp "$SCRIPT_DIR/config.json" "$INSTALL_DIR/"

# 4. Copy the service file and set up the systemd service
echo "[4/5] Setting up the systemd service..."
sudo cp "$SCRIPT_DIR/fan_control.service" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable fan_control.service

# 5. Start the service
echo "[5/5] Starting the fan control service..."
sudo systemctl restart fan_control.service

echo ""
echo "--- Installation Complete! ---"
echo "Project installed in: $INSTALL_DIR"
echo "The fan control service is now active and will start automatically on boot."
echo "To check the status, run: sudo systemctl status fan_control.service"
