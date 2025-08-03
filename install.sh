#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "--- Starting Fan Control Installation ---"

# 1. Update package list
echo "[1/3] Updating package list and installing dependencies..."
sudo apt-get update
sudo apt-get install -y python3 git python3-rpi.gpio python3-psutil

# 2. Setup the systemd service
# The script is run from inside the cloned directory, so it can find the file.
echo "[2/3] Setting up the systemd service..."
sudo cp fan_control.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable fan_control.service

# 3. Start the service
echo "[3/3] Starting the fan control service..."
sudo systemctl restart fan_control.service

echo ""
echo "--- Installation Complete! ---"
echo "The fan control service is now active and will start automatically on boot."
echo "To check the status, run: sudo systemctl status fan_control.service"
