# PWM Fan Control for Raspberry Pi

A Python script to intelligently control the Raspberry Pi fan based on CPU temperature and usage, designed to run as a systemd service.

---

## 🔧 Features

- **Variable Speed:** Adjusts fan speed based on CPU temperature thresholds.
- **CPU Load Protection:** Forces the fan to 100% speed when CPU usage is high.
- **Startup Burst:** Runs the fan at full speed for 60 seconds on boot.
- **Fully Configurable:** All parameters are managed via `config.json`.
- **Robust & Efficient:** Uses `psutil` for reliable system monitoring.
- **Automated Service:** Includes a `systemd` service file for automation.
- **One-Command Install:** A comprehensive `install.sh` script handles everything from dependencies to service setup.

---

## 🚀 Automatic Installation

For a fresh setup, run the following command:

```bash
git clone https://github.com/yassinyl/rpi-fan-control.git && cd rpi-fan-control && sudo bash install.sh

After installation, the project files will be located in:

/home/pi/rpi-fan-control

You can modify the config.json file in that directory to tune the settings.


---

🛠️ Managing the Service

✅ Check Status

fan-status

⛔ Stop the Service

fan-stop

🔄 Restart the Service (after config change)

fan-restart

📺 View Live Logs

fan-logs

> Note: You may need to run source ~/.bashrc or restart your terminal once for these commands to become active.
