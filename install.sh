#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="fan_control.service"
INSTALL_DIR="/usr/local/lib/rpi-fan-control"
CONFIG_DIR="/etc/rpi-fan-control"

if (( EUID != 0 )); then
  echo "[ERROR] Run this installer with sudo." >&2
  exit 1
fi

for file in "$SERVICE_NAME" pwm-fan-control.py config.json fan-live.sh; do
  [[ -f "$file" ]] || { echo "[ERROR] Required file not found: $file" >&2; exit 1; }
done

echo "[INFO] Installing system dependencies…"
apt-get update
apt-get install -y pigpio python3-pigpio

echo "[INFO] Installing application files…"
install -d -m 755 "$INSTALL_DIR" "$CONFIG_DIR"
install -m 755 pwm-fan-control.py "$INSTALL_DIR/pwm-fan-control.py"
if [[ ! -e "$CONFIG_DIR/config.json" ]]; then
  install -m 644 config.json "$CONFIG_DIR/config.json"
else
  echo "[INFO] Keeping existing $CONFIG_DIR/config.json"
fi
install -m 755 fan-live.sh /usr/local/bin/fan-live
install -m 644 "$SERVICE_NAME" "/etc/systemd/system/$SERVICE_NAME"

systemctl daemon-reload
systemctl enable --now pigpiod.service
systemctl enable --now "$SERVICE_NAME"
echo "[INFO] Installation complete. Edit $CONFIG_DIR/config.json to tune the fan."
