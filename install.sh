#!/bin/bash

SERVICE_NAME="fan_control.service"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"
SCRIPT_PATH="/home/pi/pwm-fan-control.py"
CONFIG_PATH="/home/pi/config.json"
LOG_PATH="/home/pi/fan_log.txt"

echo "[INFO] Installing RPi Fan Control..."

if [ -f "$SERVICE_NAME" ]; then
    sudo cp "$SERVICE_NAME" "$SERVICE_PATH"
    sudo chmod 644 "$SERVICE_PATH"
    echo "[INFO] Service file copied to $SERVICE_PATH"
else
    echo "[ERROR] Service file $SERVICE_NAME not found!"
    exit 1
fi

cp pwm-fan-control.py "$SCRIPT_PATH"
cp config.json "$CONFIG_PATH"
touch "$LOG_PATH"

sudo systemctl enable pigpiod
sudo systemctl start pigpiod

sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME"
sudo systemctl start "$SERVICE_NAME"

BASHRC="$HOME/.bashrc"
if ! grep -q "fan-status" "$BASHRC"; then
    echo "" >> "$BASHRC"
    echo "### RPi Fan Control Aliases" >> "$BASHRC"
    echo "alias fan-status='sudo systemctl status $SERVICE_NAME --no-pager -l'" >> "$BASHRC"
    echo "alias fan-restart='sudo systemctl restart $SERVICE_NAME'" >> "$BASHRC"
    echo "alias fan-start='sudo systemctl start $SERVICE_NAME'" >> "$BASHRC"
    echo "alias fan-stop='sudo systemctl stop $SERVICE_NAME'" >> "$BASHRC"
    echo "alias fan-log='tail -f $LOG_PATH'" >> "$BASHRC"
    echo "alias fan-live='while true; do speed=\$(( \$(pigs gdc 12) / 10000 )); temp=\$(awk \"{print \\\$1/1000}\" /sys/class/thermal/thermal_zone0/temp); echo \"\$(date \"+[%Y-%m-%d %H:%M:%S]\") Temp: \${temp}°C | Fan Speed: \${speed}%\"; sleep 0.5; done'" >> "$BASHRC"
    echo "[INFO] Aliases added to $BASHRC"
else
    echo "[INFO] Aliases already exist in $BASHRC"
fi

echo "[INFO] Installation complete!"
echo "Run: source ~/.bashrc"
