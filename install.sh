#!/bin/bash
set -e

echo "--- Installing RPi Fan Control ---"

# 1. Copy main files to ~/ (if not already there)
echo "[1/4] Ensuring main files are in /home/pi..."
cp -n pwm-fan-control.py config.json /home/pi/

# 2. Create systemd service
echo "[2/4] Creating systemd service..."
cat <<EOF | sudo tee /etc/systemd/system/fan_control.service > /dev/null
[Unit]
Description=Python Fan Control Script
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /home/pi/pwm-fan-control.py
Restart=on-failure
RestartSec=5s
User=pi

[Install]
WantedBy=multi-user.target
EOF

# 3. Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable fan_control.service
sudo systemctl restart fan_control.service

# 4. Add convenient aliases
echo "[3/4] Adding helpful aliases..."
BASHRC="/home/pi/.bashrc"
if ! grep -q "### Fan Control Aliases" "$BASHRC"; then
  cat <<'EOL' >> "$BASHRC"

### Fan Control Aliases
alias fan-log='tail -f /home/pi/fan_log.txt'
alias fan-full='python3 /home/pi/pwm-fan-control.py full'
EOL
fi

# 5. Final note
echo "[4/4] Done ✅"
echo "➡ Run: source ~/.bashrc"
echo "➡ Then try: fan-log  |  fan-full"
