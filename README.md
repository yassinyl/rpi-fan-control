# RPi Fan Control

A small, fail-safe PWM fan controller for a **Raspberry Pi 4**. It reads the
CPU thermal zone, controls a 4-wire fan through `pigpiod`, and runs as a
systemd service.

## Hardware

The default configuration uses **BCM GPIO 12** (physical pin 32), which is a
hardware PWM-capable pin on Raspberry Pi 4. Connect the fan's PWM input to that
pin and power the fan from an appropriate supply. Do not power a fan directly
from a GPIO pin; use a suitable driver/level shifter where the fan requires it.

> GPIO 12 and GPIO 18 share PWM channel 0; avoid using both for independent
> PWM signals. GPIO numbering in `config.json` is BCM numbering, not physical
> pin numbering.

## Installation

1. On the Raspberry Pi, clone the repository and enter its directory:

```bash
git clone <repository-url>
cd rpi-fan-control
```

2. Review and, if needed, customize the default settings before the first
   installation:

```bash
editor config.json
```

3. Make the installer executable and run it with administrator privileges:

```bash
chmod +x install.sh
sudo ./install.sh
```

4. Confirm that the service started successfully:

```bash
sudo systemctl status fan_control.service
```

The installer updates the package list, installs `pigpio` and `python3-pigpio`,
copies the Python daemon to `/usr/local/lib/rpi-fan-control`, and installs
`fan-live` in `/usr/local/bin`. It copies the initial configuration to
`/etc/rpi-fan-control/config.json`, installs `fan_control.service`, then enables
and starts both `pigpiod.service` and `fan_control.service`. Re-running the
installer preserves an existing configuration file.

After installation, edit `/etc/rpi-fan-control/config.json` to change settings
and restart the service for the change to take effect:

```bash
sudo editor /etc/rpi-fan-control/config.json
sudo systemctl restart fan_control.service
```

Useful commands:

```bash
sudo systemctl status fan_control.service
sudo systemctl restart fan_control.service
journalctl -u fan_control.service -f
fan-live
```

## Configuration

Edit `/etc/rpi-fan-control/config.json`, then restart the service. The daemon
also re-reads valid configuration changes between polling cycles.

| Setting | Meaning |
| --- | --- |
| `gpio_pin` | BCM hardware-PWM GPIO; default `12`. |
| `pwm_freq` | PWM frequency in Hz; default `25000`, typical for 4-wire fans. |
| `temp_low` / `temp_high` | Temperature range used for linear speed scaling. |
| `rpm_min` / `rpm_max` | Minimum/maximum PWM duty percentages. |
| `hysteresis` | Minimum temperature change before recalculating speed. |
| `cpu_usage_threshold` | CPU usage percent that triggers a temporary 100% boost. |
| `cpu_boost_duration` | Seconds a CPU-load boost remains active after the threshold is crossed. |
| `startup_duration` | Seconds at 100% fan speed after service startup. |
| `poll_interval` | Sensor polling period in seconds. |
| `logging_enabled` | Enables informational messages in the system journal. |

Invalid configuration is rejected without changing the current fan output. If a
temperature reading or control cycle fails, the daemon requests 100% duty as a
failsafe and writes an error to the journal.

## Development checks

```bash
python3 -m unittest discover -s tests -v
bash -n install.sh fan-live.sh
```
