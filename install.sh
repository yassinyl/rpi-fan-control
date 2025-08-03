#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "--- Starting Fan Control Installation ---"

# 1. Update package list and install dependencies
echo "[1/4] Updating dependencies..."
sudo apt-get update
sudo apt-get install -y python3 git python3-rpi.gpio python3-psutil

# 2. Correct file permissions
# The script is run from inside the cloned directory.
echo "[2/4] Correcting file permissions..."
sudo chown -R pi:pi .
# Making scripts executable as requested
chmod +x pwm-fan-control.py install.sh

# 3. Setup the systemd service
echo "[3/4] Setting up the systemd service..."
sudo cp fan_control.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable fan_control.service

# 4. Start the service
echo "[4/4] Starting the fan control service..."
sudo systemctl restart fan_control.service

echo ""
echo "--- Installation Complete! ---"
echo "The fan control service is now active and will start automatically on boot."
echo "To check the status, run: sudo systemctl status fan_control.service"
