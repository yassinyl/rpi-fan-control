# PWM Fan Control for Raspberry Pi

A Python script to intelligently control the Raspberry Pi fan based on CPU temperature and usage, designed to run as a systemd service.

---

## Features

- **Variable Speed:** Adjusts fan speed based on CPU temperature thresholds.
- **CPU Load Protection:** Forces the fan to 100% speed when CPU usage is high.
- **Startup Burst:** Runs the fan at full speed for 60 seconds on boot.
- **Fully Configurable:** All parameters are managed via `config.json`.
- **Robust & Efficient:** Uses `psutil` for reliable system monitoring.
- **Automated Service:** Includes a `systemd` service file for automation.
- **One-Command Install:** A comprehensive `install.sh` script handles everything from dependencies to service setup.

---

## Automatic Installation

For a fresh setup, this single command will clone the repository and run the installation script. It will install all necessary software and configure the service to run automatically.

```bash
git clone [https://github.com/yassinyl/rpi-fan-control.git](https://github.com/yassinyl/rpi-fan-control.git) && cd rpi-fan-control && sudo bash install.sh

After installation, the project files will be located in /home/pi/rpi-fan-control. You can modify the config.json file in that directory to tune the settings.
Managing the Service
 * Check Status:
   sudo systemctl status fan_control.service

 * Stop the Service:
   sudo systemctl stop fan_control.service

 * Restart the Service (after a config change):
   sudo systemctl restart fan_control.service

 * View Live Logs:
   journalctl -u fan_control.service -f

<!-- end list -->
