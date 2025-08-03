#!/bin/bash

echo "--- Starting RPi Fan Control Installation ---"

# Step 1: Install dependencies
echo "[1/4] Installing dependencies..."
sudo apt update
sudo apt install -y python3 python3-rpi.gpio python3-psutil git

# Step 2: Fix permissions
echo "[2/4] Correcting file permissions..."
chmod +x pwm-fan-control.py

# Step 3: Set up systemd service
echo "[3/4] Setting up the systemd service..."
SERVICE_PATH="/etc/systemd/system/fan_control.service"

sudo bash -c "cat > $SERVICE_PATH" <<EOF
[Unit]
Description=PWM Fan Control Service
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /home/$USER/rpi-fan-control/pwm-fan-control.py auto
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable fan_control.service
sudo systemctl restart fan_control.service

# Step 4: Set up aliases
echo "[4/4] Setting up aliases and starting the service..."

BASHRC_FILE="/home/$USER/.bashrc"
ALIAS_MARKER="# >>> FAN CONTROL ALIASES >>>"

# Remove old aliases if they exist
sed -i "/$ALIAS_MARKER/,/# <<< FAN CONTROL ALIASES <<</d" "$BASHRC_FILE"

# Append new aliases
cat >> "$BASHRC_FILE" <<EOF
$ALIAS_MARKER
fan-full() { python3 /home/$USER/rpi-fan-control/pwm-fan-control.py full "\$1"; }
fan-auto() { python3 /home/$USER/rpi-fan-control/pwm-fan-control.py auto; }
fan-logs() { tail -f /home/$USER/fan_log.txt; }
# <<< FAN CONTROL ALIASES <<<
EOF

echo
echo "--- Installation Complete! ---"
echo "The fan control service is now running."
echo "Aliases are available. Run 'source ~/.bashrc' or restart your terminal to use them."
