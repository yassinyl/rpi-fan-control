#!/bin/bash
set -e

echo "--- Starting RPi Fan Control Installation ---"

# [1/4] Install dependencies
echo "[1/4] Installing dependencies..."
sudo apt-get update
sudo apt-get install -y python3 git python3-rpi.gpio python3-psutil

# [2/4] Fix permissions
echo "[2/4] Correcting file permissions..."
sudo chown -R pi:pi .
chmod +x pwm-fan-control.py install.sh

# [3/4] Setup systemd service
echo "[3/4] Setting up the systemd service..."
sudo cp fan_control.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable fan_control.service

# [4/4] Add fan-full function only
echo "[4/4] Setting up aliases and starting the service..."
BASHRC_FILE="/home/pi/.bashrc"
if ! grep -q "### RPi Fan Control Aliases" "$BASHRC_FILE"; then
  echo '' >> "$BASHRC_FILE"
  echo '### RPi Fan Control Aliases' >> "$BASHRC_FILE"
  echo 'fan-full() { python3 /home/pi/rpi-fan-control/pwm-fan-control.py full "$1"; }' >> "$BASHRC_FILE"
fi

sudo systemctl restart fan_control.service

echo ""
echo "--- Installation Complete! ---"
echo "The fan control service is now running."
echo "Run 'source ~/.bashrc' or restart your terminal to use fan-full."
