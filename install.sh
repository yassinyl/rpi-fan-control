#!/bin/bash

SERVICE_NAME="fan_control.service"
USER_HOME="/home/pi"
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

echo -e "${GREEN}[INFO] Installing dependencies...${NC}"
apt-get update
apt-get install -y python3 python3-psutil python3-pip git build-essential

echo -e "${GREEN}[INFO] Installing pigpio...${NC}"

if ! command -v pigpiod &> /dev/null; then
    git clone https://github.com/joan2937/pigpio /tmp/pigpio
    cd /tmp/pigpio
    make
    make install
fi

systemctl enable pigpiod 2>/dev/null
systemctl start pigpiod 2>/dev/null || pigpiod

echo -e "${GREEN}[INFO] Installing Python pigpio module...${NC}"
pip3 install pigpio --break-system-packages

echo -e "${GREEN}[INFO] Installing files...${NC}"

cp pwm-fan-control.py "$SCRIPT_PATH"
cp config.json "$CONFIG_PATH"
touch "$LOG_PATH"

cp "$SERVICE_NAME" "$SERVICE_PATH"
chmod 644 "$SERVICE_PATH"

systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl restart "$SERVICE_NAME"

echo -e "${GREEN}[INFO] Installing fan-live tool...${NC}"

if [ -f "fan-live.sh" ]; then
    cp fan-live.sh /usr/local/bin/fan-live
    chmod +x /usr/local/bin/fan-live
fi

echo -e "${GREEN}[INFO] Installing aliases...${NC}"

if ! grep -q "fan-status" "$BASHRC"; then
    echo "" >> "$BASHRC"
    echo "### RPi Fan Control Aliases" >> "$BASHRC"
    echo "alias fan-status='sudo systemctl status $SERVICE_NAME --no-pager -l'" >> "$BASHRC"
    echo "alias fan-restart='sudo systemctl restart $SERVICE_NAME'" >> "$BASHRC"
    echo "alias fan-start='sudo systemctl start $SERVICE_NAME'" >> "$BASHRC"
    echo "alias fan-stop='sudo systemctl stop $SERVICE_NAME'" >> "$BASHRC"
    echo "alias fan-log='tail -f $LOG_PATH'" >> "$BASHRC"
    echo "alias fan-live='/usr/local/bin/fan-live'" >> "$BASHRC"

    echo -e "${GREEN}[INFO] Aliases added${NC}"
fi

echo -e "${GREEN}[INFO] Installation complete!${NC}"
echo "Run: source ~/.bashrc"
