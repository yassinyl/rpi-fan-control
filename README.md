# RPi Fan Control

Python script to intelligently control a PWM fan on a Raspberry Pi using hardware PWM and CPU metrics.

---

## 🔧 Features

- 🌀 **Variable Fan Speed**: Adjusts fan speed based on CPU temperature thresholds.
- 🚀 **Startup Boost**: Runs fan at 100% for a few seconds at boot to cool any startup heat.
- 💡 **CPU Load Response**: If CPU usage exceeds a set threshold, fan runs at 100% temporarily.
- ⚙️ **Hardware PWM**: Uses Raspberry Pi's hardware PWM via `pigpio` on GPIO12 (PWM0).
- 📁 **Custom Config**: Easily configure behavior via `config.json`.
- 📋 **Systemd Integration**: Runs as a service in the background.
- 🧰 **Convenient Aliases**: Quick commands for status, logs, and control.

---

## 📦 Installation

```bash
git clone https://github.com/yassinyl/rpi-fan-control.git
cd rpi-fan-control
chmod +x install.sh
./install.sh
source ~/.bashrc
```

---

## 🛠 Configuration

Edit the `config.json` file to set your fan thresholds, PWM frequency, polling interval, etc.

```json
{
  "gpio_pin": 12,
  "pwm_freq": 25000,
  "poll_interval": 3,
  "hysteresis": 3,
  "cpu_usage_threshold": 85,
  "startup_duration": 30,
  "fan_levels": [
    { "limit": 48, "speed": 0 },
    { "limit": 55, "speed": 30 },
    { "limit": 60, "speed": 50 },
    { "limit": 70, "speed": 70 },
    { "limit": 90, "speed": 90 }
  ]
}
```

---

## 🚀 Aliases

These are added automatically to your `.bashrc`:

```bash
fan-status     # Check systemd service status
fan-restart    # Restart the fan service
fan-stop       # Stop the fan service
fan-logs       # Tail the fan log live
```

---

## 📂 File Structure

```
rpi-fan-control/
│
├── pwm-fan-control.py      # Main control script
├── config.json             # Configurable fan logic
├── fan_control.service     # systemd service file
├── install.sh              # Easy setup script
└── fan_log.txt             # Runtime log file (auto-created)
```

---

## 📌 Notes

- Make sure the `pigpiod` daemon is enabled on boot:
  
  ```bash
  sudo systemctl enable pigpiod
  sudo systemctl start pigpiod
  ```

- Uses GPIO 12 (PWM0) for hardware PWM. Ensure your fan supports PWM input and is wired correctly.

---

## 📃 License

MIT License

---

## 💬 Support

For issues or suggestions, open an [Issue](https://github.com/yassinyl/rpi-fan-control/issues).
