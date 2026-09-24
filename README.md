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

These steps assume Raspberry Pi OS is already installed, the Pi has Internet
access, and the fan is wired as described above. Run them on the Raspberry Pi,
not on another computer.

### 1. Update Raspberry Pi OS and install Git

```bash
sudo apt update
sudo apt full-upgrade -y
sudo apt install -y git
sudo reboot
```

After the Pi restarts, reconnect by SSH or open a terminal.

### 2. Download the project

```bash
cd ~
git clone https://github.com/yassinyl/rpi-fan-control.git
cd rpi-fan-control
```

If the project was already cloned, update it instead:

```bash
cd ~/rpi-fan-control
git pull --ff-only
```

### 3. Check the default settings (optional)

The default settings use BCM GPIO 12 and a 25 kHz PWM signal. Review them
before installation if your wiring or fan needs different values:

```bash
cat config.json
```

### 4. Run the installer

```bash
chmod +x install.sh
sudo ./install.sh
```

The installer installs the Python daemon in `/usr/local/lib/rpi-fan-control`,
keeps configuration in `/etc/rpi-fan-control/config.json`, installs
`pigpiod.service`, and enables both services. Re-running it preserves an
existing configuration file.

### 5. Confirm that the services are running

```bash
sudo systemctl status pigpiod.service --no-pager
sudo systemctl status fan_control.service --no-pager
journalctl -u fan_control.service -n 50 --no-pager
```

`active (running)` for both services means installation succeeded.

### 6. Monitor and tune the fan

```bash
fan-live
```

Press `Ctrl+C` to stop the live monitor. To change the behaviour, edit the
installed configuration and restart the controller:

```bash
sudo nano /etc/rpi-fan-control/config.json
sudo systemctl restart fan_control.service
journalctl -u fan_control.service -f
```

Use `Ctrl+C` to stop following the journal. The full configuration reference
is in the next section.

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
