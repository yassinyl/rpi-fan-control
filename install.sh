---

**install.sh**
```bash
#!/bin/bash

SERVICE_NAME="fan.control.service"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"
SCRIPT_PATH="/home/pi/pwm-fan-control.py"
CONFIG_PATH="/home/pi/config.json"
LOG_PATH="/home/pi/fan_log.txt"

echo "[INFO] Installing RPi Fan Control..."

# Copy service file
sudo cp "$SERVICE_NAME" "$SERVICE_PATH"
sudo chmod 644 "$SERVICE_PATH"

# Copy script and config to /home/pi
cp pwm-fan-control.py "$SCRIPT_PATH"
cp config.json "$CONFIG_PATH"
touch "$LOG_PATH"

# Enable pigpio daemon
sudo systemctl enable pigpiod
sudo systemctl start pigpiod

# Enable and start fan service
sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME"
sudo systemctl start "$SERVICE_NAME"

# Add aliases to .bashrc if not present
BASHRC="$HOME/.bashrc"
if ! grep -q "fan-status" "$BASHRC"; then
    echo "" >> "$BASHRC"
    echo "# Fan Control Aliases" >> "$BASHRC"
    echo "alias fan-status='systemctl status $SERVICE_NAME --no-pager -l'" >> "$BASHRC"
    echo "alias fan-restart='sudo systemctl restart $SERVICE_NAME'" >> "$BASHRC"
    echo "alias fan-stop='sudo systemctl stop $SERVICE_NAME'" >> "$BASHRC"
    echo "alias fan-logs='tail -f $LOG_PATH'" >> "$BASHRC"
fi

echo "[INFO] Installation complete!"
echo "Run: source ~/.bashrc"
