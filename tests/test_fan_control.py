import importlib.util
import json
import sys
import tempfile
import types
import unittest
from pathlib import Path


fake_pigpio = types.SimpleNamespace(OUTPUT=1, pi=lambda: None)
sys.modules.setdefault("pigpio", fake_pigpio)
SPEC = importlib.util.spec_from_file_location("fan_control", Path(__file__).parents[1] / "pwm-fan-control.py")
fan_control = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(fan_control)


class ConfigurationTests(unittest.TestCase):
    def write_config(self, overrides):
        path = Path(tempfile.mkstemp()[1])
        path.write_text(json.dumps({**fan_control.DEFAULTS, **overrides}), encoding="utf-8")
        self.addCleanup(path.unlink)
        return path

    def test_load_config_accepts_valid_values(self):
        config = fan_control.load_config(self.write_config({"temp_low": 40, "temp_high": 65}))
        self.assertEqual(config["temp_high"], 65)

    def test_load_config_rejects_invalid_temperature_range(self):
        with self.assertRaisesRegex(ValueError, "temp_high"):
            fan_control.load_config(self.write_config({"temp_low": 70, "temp_high": 70}))

    def test_speed_curve_uses_configured_maximum(self):
        controller = object.__new__(fan_control.FanController)
        controller.config = {"temp_low": 40, "temp_high": 60, "rpm_min": 20, "rpm_max": 80}
        self.assertEqual(controller.speed_for_temp(40), 0)
        self.assertEqual(controller.speed_for_temp(50), 50)
        self.assertEqual(controller.speed_for_temp(60), 80)


if __name__ == "__main__":
    unittest.main()
