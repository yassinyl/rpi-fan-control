#!/bin/bash

SERVICE_NAME="fan_control.service"
USER_HOME="/home/pi" # Change if needed
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"
SCRIPT_PATH="$USER_HOME/pwm-fan-control.py"
CONFIG_PATH="$USER_HOME/config.json"
LOG_PATH="$USER_HOME/fan_log.txt"
BASHRC="$USER_HOME/.bashrc"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[ERROR] Please run as root (use sudo)${NC}"
  exit 1
fi

echo -e "${GREEN}[INFO] Installing RPi Fan Control...${NC}"

for f in "$SERVICE_NAME" "pwm-fan-control.py" "config.json"; do
  if [ ! -f "$f" ]; then
    echo -e "${RED}[ERROR] File $f not found!${NC}"
    exit 1
  fi
done

sudo cp "$SERVICE_NAME" "$SERVICE_PATH"
sudo chmod 644 "$SERVICE_PATH"
echo -e "${GREEN}[INFO] Service file copied to $SERVICE_PATH${NC}"

cp pwm-fan-control.py "$SCRIPT_PATH"
cp config.json "$CONFIG_PATH"
touch "$LOG_PATH"

if ! command -v pigpiod &> /dev/null; then
    echo -e "${GREEN}[INFO] pigpiod not found. Installing...${NC}"
    apt-get update
    apt-get install -y pigpio
fi

systemctl enable pigpiod
systemctl start pigpiod

systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl start "$SERVICE_NAME"

if ! grep -q "fan-status" "$BASHRC"; then
    echo "" >> "$BASHRC"
    echo "### RPi Fan Control Aliases" >> "$BASHRC"
    echo "alias fan-status='sudo systemctl status $SERVICE_NAME --no-pager -l'" >> "$BASHRC"
    echo "alias fan-restart='sudo systemctl restart $SERVICE_NAME'" >> "$BASHRC"
    echo "alias fan-start='sudo systemctl start $SERVICE_NAME'" >> "$BASHRC"
    echo "alias fan-stop='sudo systemctl stop $SERVICE_NAME'" >> "$BASHRC"
    echo "alias fan-log='tail -f $LOG_PATH'" >> "$BASHRC"
    echo "alias fan-live='while true; do speed=\$(( \\$(pigs gdc 12) / 10000 )); temp=\\$(awk "{print \\$1/1000}" /sys/class/thermal/thermal_zone0/temp); echo "\\$(date "+[%Y-%m-%d %H:%M:%S]") Temp[\$temp°C] Speed[\$speed%]"; sleep 2; done'" >> "$BASHRC"
    echo -e "${GREEN}[INFO] Aliases added to $BASHRC${NC}"
else
    echo "[INFO] Aliases already exist in $BASHRC"
fi

echo -e "${GREEN}[INFO] Installation complete!${NC}"
echo "Run: source ~/.bashrc"