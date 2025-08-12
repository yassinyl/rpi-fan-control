#!/usr/bin/python3

import time, json, signal, psutil, pigpio

from datetime import datetime

import sys

CONFIG_PATH = "/home/pi/config.json"

LOG_PATH = "/home/pi/fan_log.txt"

def load_config():

    try:

        with open(CONFIG_PATH, "r") as f:

            return json.load(f)

    except Exception as e:

        log(f"[ERROR] Failed to load config: {e}")

        return {}

config = load_config()

LOGGING_ENABLED = config.get("logging_enabled", True)

def log(message):

    if not LOGGING_ENABLED:

        return

    timestamp = datetime.now().strftime("[%Y-%m-%d %H:%M:%S]")

    print(f"{timestamp} {message}", flush=True)

    try:

        with open(LOG_PATH, "a") as f:

            f.write(f"{timestamp} {message}\n")

    except Exception as e:

        print(f"[ERROR] Failed to write log: {e}", flush=True)

class FanController:

    def __init__(self):

        self.load_config_values()

        self.pi = pigpio.pi()

        if not self.pi.connected:

            log("[ERROR] Cannot connect to pigpio daemon.")

            sys.exit(1)

        self.pi.set_mode(self.gpio, pigpio.OUTPUT)

        self.pi.hardware_PWM(self.gpio, self.freq, 0)

        self.last_speed = 0

        self.last_temp = None

        self.force_mode = False

        self.force_start = None

    def load_config_values(self):

        self.config = load_config()

        global LOGGING_ENABLED

        LOGGING_ENABLED = self.config.get("logging_enabled", True)

        self.gpio = self.config.get("gpio_pin", 12)

        self.freq = self.config.get("pwm_freq", 25000)

        self.interval = self.config.get("poll_interval", 3)

        self.hysteresis = self.config.get("hysteresis", 3)

        self.cpu_threshold = self.config.get("cpu_usage_threshold", 85)

        self.startup_duration = self.config.get("startup_duration", 2)

        self.temp_low = self.config.get("temp_low", 40)

        self.temp_high = self.config.get("temp_high", 55)

        self.rpm_min = self.config.get("rpm_min", 15)

        self.rpm_max = self.config.get("rpm_max", 100)

    def set_fan_speed(self, speed, reason=""):

        speed = max(0, min(speed, 100))

        duty_cycle = int(speed * 10000)

        self.pi.hardware_PWM(self.gpio, self.freq, duty_cycle)

        self.last_speed = speed

        log(f"Fan speed set to {speed}% {reason}")

    def get_temp(self):

        try:

            with open("/sys/class/thermal/thermal_zone0/temp", "r") as f:

                return int(f.read()) / 1000

        except Exception as e:

            log(f"[ERROR] Cannot read temperature: {e}")

            return 0

    def get_cpu_usage(self):

        return psutil.cpu_percent(interval=None)

    def get_speed_from_temp(self, temp):

        if temp <= self.temp_low:

            return 0

        elif temp >= self.temp_high:

            return 100

        else:

            scale = (temp - self.temp_low) / (self.temp_high - self.temp_low)

            speed = self.rpm_min + scale * (self.rpm_max - self.rpm_min)

            return int(speed)

    def cleanup(self):

        self.set_fan_speed(0)

        self.pi.stop()

        log("Fan control stopped.")

    def handle_sigterm(self, sig, frame):

        self.cleanup()

        sys.exit(0)

    def run(self):

        log("Fan control started (auto mode).")

        signal.signal(signal.SIGTERM, self.handle_sigterm)

        self.set_fan_speed(100, reason="[Startup]")

        time.sleep(self.startup_duration)

        while True:

            self.load_config_values()

            temp = self.get_temp()

            cpu = self.get_cpu_usage()

            if cpu >= self.cpu_threshold:

                if not self.force_mode:

                    self.force_mode = True

                    self.force_start = time.time()

                    self.set_fan_speed(100, reason=f"[CPU {cpu}%]")

            elif self.force_mode and time.time() - self.force_start >= self.startup_duration:

                self.force_mode = False

                log(f"CPU usage dropped to {cpu}% → Resuming auto mode")

            if not self.force_mode:

                if self.last_temp is None or abs(temp - self.last_temp) >= self.hysteresis:

                    speed = self.get_speed_from_temp(temp)

                    if abs(speed - self.last_speed) >= 1 or speed in (0, 100):

                        self.set_fan_speed(speed, reason=f"[Temp {temp}°C]")

                        self.last_temp = temp

                else:

                    log(f"Temp: {temp}°C, Fan speed: {self.last_speed}% (within hysteresis)")

            time.sleep(self.interval)

if __name__ == "__main__":

    try:

        FanController().run()

    except KeyboardInterrupt:

        FanController().cleanup()

    except Exception as e:

        log(f"[ERROR] Unhandled exception: {e}")

        FanController().cleanup()