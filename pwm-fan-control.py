#!/usr/bin/env python3
"""Temperature and CPU-load controlled PWM fan daemon for Raspberry Pi 4."""

import argparse
import json
import logging
import signal
import sys
import time
from pathlib import Path

import pigpio

DEFAULT_CONFIG_PATH = Path("/etc/rpi-fan-control/config.json")
THERMAL_PATH = Path("/sys/class/thermal/thermal_zone0/temp")
DEFAULTS = {
    "logging_enabled": True, "gpio_pin": 12, "pwm_freq": 25000,
    "poll_interval": 3, "hysteresis": 3, "cpu_usage_threshold": 70,
    "cpu_boost_duration": 10, "startup_duration": 10, "temp_low": 45,
    "temp_high": 70, "rpm_min": 30, "rpm_max": 100,
}


def load_config(path):
    """Load and validate configuration, failing safely before driving the fan."""
    try:
        with Path(path).open(encoding="utf-8") as config_file:
            values = {**DEFAULTS, **json.load(config_file)}
    except (OSError, json.JSONDecodeError) as error:
        raise ValueError(f"Cannot load configuration {path}: {error}") from error

    numeric = ("gpio_pin", "pwm_freq", "poll_interval", "hysteresis",
               "cpu_usage_threshold", "cpu_boost_duration", "startup_duration",
               "temp_low", "temp_high", "rpm_min", "rpm_max")
    if any(not isinstance(values[key], (int, float)) for key in numeric):
        raise ValueError("All numeric configuration values must be numbers")
    if not 0 <= values["gpio_pin"] <= 53:
        raise ValueError("gpio_pin must be a valid BCM GPIO number (0-53)")
    if values["pwm_freq"] <= 0 or values["poll_interval"] <= 0:
        raise ValueError("pwm_freq and poll_interval must be greater than zero")
    if values["temp_high"] <= values["temp_low"]:
        raise ValueError("temp_high must be greater than temp_low")
    if not 0 <= values["rpm_min"] <= values["rpm_max"] <= 100:
        raise ValueError("rpm_min and rpm_max must be between 0 and 100")
    if not 0 <= values["cpu_usage_threshold"] <= 100:
        raise ValueError("cpu_usage_threshold must be between 0 and 100")
    if values["hysteresis"] < 0 or values["startup_duration"] < 0 or values["cpu_boost_duration"] < 0:
        raise ValueError("durations and hysteresis cannot be negative")
    return values


def read_cpu_times():
    with Path("/proc/stat").open(encoding="utf-8") as stat_file:
        fields = next(line.split() for line in stat_file if line.startswith("cpu "))
    values = [int(value) for value in fields[1:]]
    idle = values[3] + (values[4] if len(values) > 4 else 0)
    return sum(values), idle


class FanController:
    def __init__(self, config_path, pi_factory=pigpio.pi):
        self.config_path = Path(config_path)
        self.pi_factory = pi_factory
        self.pi = None
        self.running = True
        self.last_speed = None
        self.last_temp = None
        self.cpu_times = read_cpu_times()
        self.boost_until = 0
        self.config = load_config(self.config_path)
        self.configure_logging()

    def configure_logging(self):
        logging.basicConfig(level=logging.INFO if self.config["logging_enabled"] else logging.WARNING,
                            format="%(asctime)s %(levelname)s %(message)s")

    def reload_config(self):
        new_config = load_config(self.config_path)
        changed_pwm = any(new_config[key] != self.config[key] for key in ("gpio_pin", "pwm_freq"))
        self.config = new_config
        self.configure_logging()
        if changed_pwm and self.pi:
            logging.warning("GPIO or PWM frequency changed; applying the new PWM settings")
            self.pi.set_mode(self.config["gpio_pin"], pigpio.OUTPUT)
            self.set_fan_speed(self.last_speed or 0, force=True)

    def connect(self):
        for _ in range(10):
            self.pi = self.pi_factory()
            if self.pi.connected:
                self.pi.set_mode(self.config["gpio_pin"], pigpio.OUTPUT)
                return
            self.pi.stop()
            logging.info("Waiting for pigpiod…")
            time.sleep(1)
        raise RuntimeError("Cannot connect to pigpiod")

    def set_fan_speed(self, speed, reason="", force=False):
        speed = max(0, min(round(speed), 100))
        if not force and speed == self.last_speed:
            return
        status = self.pi.hardware_PWM(self.config["gpio_pin"], self.config["pwm_freq"], speed * 10000)
        if status != 0:
            raise RuntimeError(f"pigpio failed to set PWM (error {status})")
        self.last_speed = speed
        logging.info("Fan speed set to %d%% %s", speed, reason)

    def get_temp(self):
        try:
            return int(THERMAL_PATH.read_text(encoding="utf-8").strip()) / 1000
        except (OSError, ValueError) as error:
            raise RuntimeError(f"Cannot read CPU temperature: {error}") from error

    def get_cpu_usage(self):
        current = read_cpu_times()
        total_delta = current[0] - self.cpu_times[0]
        idle_delta = current[1] - self.cpu_times[1]
        self.cpu_times = current
        return 0 if total_delta <= 0 else 100 * (total_delta - idle_delta) / total_delta

    def speed_for_temp(self, temp):
        if temp <= self.config["temp_low"]:
            return 0
        if temp >= self.config["temp_high"]:
            return self.config["rpm_max"]
        fraction = (temp - self.config["temp_low"]) / (self.config["temp_high"] - self.config["temp_low"])
        return self.config["rpm_min"] + fraction * (self.config["rpm_max"] - self.config["rpm_min"])

    def run(self):
        self.connect()
        self.set_fan_speed(100, "[startup]")
        time.sleep(self.config["startup_duration"])
        while self.running:
            try:
                self.reload_config()
                temp, cpu = self.get_temp(), self.get_cpu_usage()
                now = time.monotonic()
                if cpu >= self.config["cpu_usage_threshold"]:
                    self.boost_until = now + self.config["cpu_boost_duration"]
                if now < self.boost_until:
                    self.set_fan_speed(100, f"[CPU {cpu:.1f}%]")
                elif self.last_temp is None or abs(temp - self.last_temp) >= self.config["hysteresis"]:
                    self.set_fan_speed(self.speed_for_temp(temp), f"[temperature {temp:.1f}°C]")
                    self.last_temp = temp
            except ValueError as error:
                logging.error("Invalid configuration; keeping current fan speed: %s", error)
            except RuntimeError as error:
                logging.error("Control cycle failed; setting fan to 100%%: %s", error)
                self.set_fan_speed(100, "[failsafe]")
            time.sleep(self.config["poll_interval"])

    def stop(self, *_):
        self.running = False

    def cleanup(self):
        if self.pi:
            try:
                self.set_fan_speed(0, "[shutdown]")
            except RuntimeError as error:
                logging.error("Could not stop PWM during shutdown: %s", error)
            finally:
                self.pi.stop()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, default=DEFAULT_CONFIG_PATH)
    args = parser.parse_args()
    controller = FanController(args.config)
    signal.signal(signal.SIGTERM, controller.stop)
    signal.signal(signal.SIGINT, controller.stop)
    try:
        controller.run()
    finally:
        controller.cleanup()


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, ValueError) as error:
        logging.error("Fan controller stopped: %s", error)
        sys.exit(1)
