#!/bin/bash
set -e

# The final, permanent location for the application files
INSTALL_DIR="/home/pi/rpi-fan-control"

echo "--- Starting RPi Fan Control Installation ---"

# 1. Install dependencies
echo "[1/4] Installing dependencies..."
sudo apt-get update
sudo apt-get install -y python3 git python3-rpi.gpio python3-psutil

# 2. Create install directory and copy files from the cloned repo
echo "[2/4] Copying application files to $INSTALL_DIR..."
sudo mkdir -p "$INSTALL_DIR"
# The script is run from the cloned repo, so the source is the current directory (.)
sudo cp ./pwm-fan-control.py "$INSTALL_DIR/"
sudo cp ./config.json "$INSTALL_DIR/"

# 3. CRITICAL FIX: Ensure the installed files are owned by the 'pi' user
echo "[3/4] Setting correct file permissions..."
sudo chown -R pi:pi "$INSTALL_DIR"

# 4. Setup and start the systemd service
echo "[4/4] Setting up and starting the systemd service..."
sudo cp ./fan_control.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable fan_control.service
sudo systemctl restart fan_control.service

echo ""
echo "--- Installation Complete! ---"
echo "The fan service is now running. You can delete the cloned repository folder."
echo "To check status, run: fan-status"
