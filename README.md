---

# RPi Fan Control

Python script to control a PWM fan on a Raspberry Pi 4 using hardware PWM and CPU/temperature logic.

---

## 🔧 Features
- 🌀 **Variable Fan Speed**: Adjusts speed between `rpm_min` and `rpm_max` based on CPU temperature.
- 🚀 **Startup Boost**: Runs fan at 100% for a short time at boot.
- 💡 **CPU Load Trigger**: Runs fan at 100% if CPU usage exceeds threshold.
- ⚙️ **Hardware PWM**: Uses GPIO12 (PWM0) via `pigpio`.
- 📁 **Custom Config**: All settings in `config.json`.
- 📋 **Systemd Service**: Auto start at boot.
- 🧰 **Optional Logging**: Enable/disable in config.

---

## 📦 Installation
```
git clone https://github.com/yassinyl/rpi-fan-control.git
cd rpi-fan-control
chmod +x install.sh
./install.sh
```

```
source ~/.bashrc
```

---

🛠 Configuration

Edit config.json to suit your needs:

```
{
  "logging_enabled": false,
  "gpio_pin": 12,
  "pwm_freq": 25000,
  "poll_interval": 3,
  "hysteresis": 3,
  "cpu_usage_threshold": 70,
  "startup_duration": 10,
  "temp_low": 45,
  "temp_high": 70,
  "rpm_min": 30,
  "rpm_max": 100
}
```

Key Parameters:

logging_enabled → Enable/disable log file writing.

temp_low / temp_high → Temperature range for speed scaling.

rpm_min / rpm_max → Minimum and maximum PWM % output.

cpu_usage_threshold → Fan boost when CPU load is high.

startup_duration → Time in seconds at 100% speed after boot.



---

🚀 Aliases
Added to .bashrc:

fan-status     # Check service status

fan-restart    # Restart service

fan-start      # Start service

fan-stop       # Stop service

fan-log        # Live logs

fan-live       # Live fan speed and temperature monitoring


---

📂 File Structure

rpi-fan-control-custom/
│
├── pwm-fan-control.py   # Main script
├── config.json          # Settings
├── fan.control.service  # systemd service file
├── install.sh           # Setup script
└── fan_log.txt          # Log file (if enabled)


---

📌 Notes

Make sure pigpiod is running:


sudo systemctl enable pigpiod
sudo systemctl start pigpiod

Uses GPIO 12 (PWM0) — ensure wiring is correct.



---

📃 License

MIT License

---
