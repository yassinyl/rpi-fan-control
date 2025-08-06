#!/bin/bash
set -e

INSTALL_DIR="/home/pi/rpi-fan-control"
SERVICE_FILE="fan_control.service"

echo "--- Starting RPi Fan Control Installation ---"

# 1. Install dependencies
echo "[1/5] Installing dependencies..."
sudo apt-get update
sudo apt-get install -y python3 python3-psutil pigpio git

# 2. Copy files
echo "[2/5] Copying files to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
cp pwm-fan-control.py config.json "$INSTALL_DIR"
cp fan_control.service "$INSTALL_DIR"

# 3. Install systemd service
echo "[3/5] Setting up systemd service..."
sudo cp "$INSTALL_DIR/$SERVICE_FILE" /etc/systemd/system/
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable fan_control.service
sudo systemctl restart fan_control.service

# 4. Create log file
touch "$INSTALL_DIR/fan_log.txt"

# 5. Add aliases to .bashrc
echo "[4/5] Adding aliases to ~/.bashrc..."
ALIAS_START="### RPi Fan Control Aliases"
if ! grep -q "$ALIAS_START" ~/.bashrc; then
    {
        echo ""
        echo "### RPi Fan Control Aliases"
        echo "alias fan-status='sudo systemctl status fan_control.service'"
        echo "alias fan-restart='sudo systemctl restart fan_control.service'"
        echo "alias fan-stop='sudo systemctl stop fan_control.service'"
        echo "alias fan-logs='tail -f $INSTALL_DIR/fan_log.txt'"
    } >> ~/.bashrc
fi

echo "[5/5] Installation complete. Please run: source ~/.bashrc"
