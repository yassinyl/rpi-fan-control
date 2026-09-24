#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH="${1:-/etc/rpi-fan-control/config.json}"
GPIO_PIN=$(python3 -c 'import json, sys; print(json.load(open(sys.argv[1]))["gpio_pin"])' "$CONFIG_PATH")

while :; do
  temp=$(awk '{print $1 / 1000}' /sys/class/thermal/thermal_zone0/temp)
  duty=$(pigs gdc "$GPIO_PIN")
  printf '\033[H\033[2JTime       : %s\nCPU Temp   : %s°C\nFan Speed  : %s%%\nGPIO       : BCM %s\n' \
    "$(date '+%H:%M:%S')" "$temp" "$((duty / 10000))" "$GPIO_PIN"
  sleep 2
done
