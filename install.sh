#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "--- Starting Fan Control Installation ---"

# 1. Update package list and install dependencies
echo "[1/5] Updating dependencies..."
sudo apt-get update
sudo apt-get install -y python3 git python3-rpi.gpio python3-psutil

# 2. Correct file permissions
echo "[2/5] Correcting file permissions for the 'pi' user..."
sudo chown -R pi:pi .
chmod +x pwm-fan-control.py install.sh

# 3. Setup the systemd service
echo "[3/5] Setting up the systemd service..."
sudo cp fan_control.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable fan_control.service

# 4. Add command aliases for easy management
echo "[4/5] Setting up convenient command aliases..."
BASHRC_FILE="/home/pi/.bashrc"
# Check if aliases are not already added to prevent duplicates
if ! grep -q "### RPi Fan Control Aliases" "$BASHRC_FILE"; then
  echo '' >> "$BASHRC_FILE"
  echo '### RPi Fan Control Aliases' >> "$BASHRC_FILE"
  echo "alias fan-status='sudo systemctl status fan_control.service'" >> "$BASHRC_FILE"
  echo "alias fan-restart='sudo systemctl restart fan_control.service'" >> "$BASHRC_FILE"
  echo "alias fan-stop='sudo systemctl stop fan_control.service'" >> "$BASHRC_FILE"
  echo "alias fan-logs='tail -f /home/pi/rpi-fan-control/fan_log.txt'" >> "$BASHRC_FILE"
  # Using a function for fan-full to accept an argument
  echo 'fan-full() {' >> "$BASHRC_FILE"
  echo '    # Runs fan at full speed for a custom duration (default 60s)' >> "$BASHRC_FILE"
  echo '    python3 /home/pi/rpi-fan-control/pwm-fan-control.py full "$1"' >> "$BASHRC_FILE"
  echo '}' >> "$BASHRC_FILE"
  echo "Aliases and functions added to $BASHRC_FILE"
else
  echo "Aliases and functions already exist. Skipping."
fi

# 5. Start the service
echo "[5/5] Starting the fan control service..."
sudo systemctl restart fan_control.service

echo ""
echo "--- Installation Complete! ---"
echo "The fan control service is now active."
echo "Aliases (fan-status, fan-restart, etc.) are available."
echo "Please run 'source ~/.bashrc' or restart your terminal to use them."
