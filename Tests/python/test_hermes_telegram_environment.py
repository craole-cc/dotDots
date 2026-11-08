"""Exercise the Telegram migration using synthetic secrets in temporary files."""

import importlib.util
from pathlib import Path
import stat
import tempfile
import unittest

from dotenv import dotenv_values


SCRIPT = Path(__file__).resolve().parents[2] / "Modules/nix/home/ai/agents/hermes/connection/telegram_environment.py"
SPEC = importlib.util.spec_from_file_location("telegram_environment", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class TelegramEnvironmentTest(unittest.TestCase):
    def test_only_telegram_values_survive_with_exact_literals(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "legacy.env"
            destination = Path(directory) / "new" / "telegram.env"
            original = (
                "TELEGRAM_BOT_TOKEN='fake:token'\n"
                "TELEGRAM_ALLOWED_USERS=123,456\n"
                "TELEGRAM_HOME_CHANNEL_NAME=\"Owner's \\\\ notes ${LITERAL}\"\n"
                "TELEGRAM_HOME_CHANNEL_THREAD_ID=\n"
                "OPENAI_API_KEY=excluded\nWHATSAPP_ALLOWED_USERS=excluded\n"
            )
            source.write_text(original)
            MODULE.prepare(source, destination)
            expected = {key: value for key, value in dotenv_values(source, interpolate=False).items() if key.startswith("TELEGRAM_")}
            self.assertEqual(dotenv_values(destination, interpolate=False), expected)
            self.assertEqual(stat.S_IMODE(destination.stat().st_mode), 0o600)
            self.assertEqual(source.read_text(), original)
            self.assertEqual(list(destination.parent.glob(".telegram-env-*")), [])

    def test_refusal_preserves_existing_destination(self):
        for content in (
            "TELEGRAM_BOT_TOKEN=fake\n",
            "TELEGRAM_ALLOWED_USERS=123\n",
            "TELEGRAM_BOT_TOKEN=fake\nTELEGRAM_ALLOWED_USERS=123\nTELEGRAM_ALLOW_ALL_USERS=true\n",
        ):
            with self.subTest(content=content), tempfile.TemporaryDirectory() as directory:
                source = Path(directory) / "legacy.env"
                destination = Path(directory) / "telegram.env"
                source.write_text(content)
                destination.write_text("preserved")
                with self.assertRaises(ValueError):
                    MODULE.prepare(source, destination)
                self.assertEqual(destination.read_text(), "preserved")


if __name__ == "__main__":
    unittest.main()
