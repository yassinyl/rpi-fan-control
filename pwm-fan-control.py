#!/usr/bin/python3

import RPi.GPIO as GPIO
import time
from datetime import datetime
import sys
import os
import signal
import json
import psutil

CONFIG_PATH = '/home/pi/rpi-fan-control/config.json'
LOG_FILE_PATH = '/home/pi/rpi-fan-control/fan_log.txt'

def load_config():
    with open(CONFIG_PATH, 'r') as f:
        return json.load(f)

config = load_config()

LOCK_FILE = "/tmp/fan_control.lock"
GPIO_PIN = config['gpio_pin']
PWM_FREQ = config['pwm_freq']
POLL_INTERVAL = config['poll_interval']
HYSTERESIS = config['hysteresis']
FAN_LEVELS = config['fan_levels']
CPU_USAGE_THRESHOLD = config['cpu_usage_threshold']

def get_temp():
    try:
        temps = psutil.sensors_temperatures()
        if 'cpu_thermal' in temps:
            return round(temps['cpu_thermal'][0].current)
    except Exception as e:
        log(f"Error getting temp: {e}")
    return 100

def get_cpu_usage():
    return psutil.cpu_percent(interval=1)

def get_fan_speed(temp):
    for level in FAN_LEVELS:
        if temp < level['limit']:
            return level['speed']
    return 100

def log(msg):
    with open(LOG_FILE_PATH, "a") as f:
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        f.write(f"[{timestamp}] {msg}\n")

def create_lock(mode):
    with open(LOCK_FILE, "w") as f:
        f.
