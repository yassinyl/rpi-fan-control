#!/usr/bin/python3

import RPi.GPIO as GPIO

import time

from datetime import datetime

import sys

import os

import signal

import json

import psutil

def load_config():

    config_path = '/home/pi/rpi-fan-control/config.json'

    with open(config_path, 'r') as f:

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

    with open("/home/pi/rpi-fan-control/fan_log.txt", "a") as f:

        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        f.write(f"[{timestamp}] {msg}\n")

def create_lock(mode):

    with open(LOCK_FILE, "w") as f:

        f.write(f"{os.getpid()}:{mode}")

def remove_lock():

    if os.path.exists(LOCK_FILE):

        os.remove(LOCK_FILE)

def get_lock_info():

    if not os.path.exists(LOCK_FILE):

        return None, None

    try:

        with open(LOCK_FILE, "r") as f:

            content = f.read()

            pid, mode = content.strip().split(":")

            return int(pid), mode

    except:

        return None, None

def is_running(pid):

    return psutil.pid_exists(pid)

fan_pwm = None

try:

    other_pid, mode = get_lock_info()

    is_full_mode = len(sys.argv) > 1 and sys.argv[1] == "full"

    full_duration = int(sys.argv[2]) if is_full_mode and len(sys.argv) > 2 else 60

    if other_pid and is_running(other_pid):

        if is_full_mode:

            if mode == "full":

                print("Manual full mode already running.")

                sys.exit(1)

            else:

                os.kill(other_pid, signal.SIGTERM)

                time.sleep(1)

        else:

            print("Script is already running. Exiting.")

            log("Attempted to start auto mode but it's already running.")

            sys.exit(1)

    create_lock("full" if is_full_mode else "auto")

    GPIO.setmode(GPIO.BCM)

    GPIO.setwarnings(False)

    GPIO.setup(GPIO_PIN, GPIO.OUT)

    fan_pwm = GPIO.PWM(GPIO_PIN, PWM_FREQ)

    fan_pwm.start(0)

    current_speed = -1

    if is_full_mode:

        log(f"Manual full speed mode started ({full_duration} seconds).")

        fan_pwm.ChangeDutyCycle(100)

        time.sleep(full_duration)

        log("Manual full speed mode ended. Restarting auto mode...")

        remove_lock()

        subprocess.Popen(

            ["nohup", "python3", "/home/pi/pwm-fan-control.py"],

            stdout=subprocess.DEVNULL,

            stderr=subprocess.DEVNULL,

            preexec_fn=os.setpgrp

        )

        sys.exit(0)

    fan_pwm.ChangeDutyCycle(100)

    time.sleep(60)

    log("Fan control started (auto mode).")

    last_temp = None

    force_full = False

    while True:

        cpu_usage = get_cpu_usage()

        if cpu_usage >= CPU_USAGE_THRESHOLD:

            if not force_full:

                fan_pwm.ChangeDutyCycle(100)

                log(f"CPU usage {cpu_usage:.1f}% → Fan forced to 100%")

                force_full = True

            time.sleep(POLL_INTERVAL)

            continue

        elif force_full and cpu_usage < CPU_USAGE_THRESHOLD:

            log(f"CPU usage dropped to {cpu_usage:.1f}% → Resuming auto mode")

            force_full = False

            current_speed = -1

        t = get_temp()

        if last_temp is None:

            last_temp = t

        if abs(t - last_temp) >= HYSTERESIS:

            target_speed = get_fan_speed(t)

            if target_speed != current_speed:

                fan_pwm.ChangeDutyCycle(target_speed)

                log(f"Temp: {t}°C → Fan speed set to {target_speed}%")

                current_speed = target_speed

            else:

                log(f"Temp: {t}°C, Fan speed: {current_speed}% (same speed)")

            last_temp = t

        else:

            log(f"Temp: {t}°C, Fan speed: {current_speed}% (within hysteresis)")

        time.sleep(POLL_INTERVAL)

except KeyboardInterrupt:

    log("Stopping fan control by user.")

finally:

    if fan_pwm:

        fan_pwm.stop()

    GPIO.cleanup()

    remove_lock()

