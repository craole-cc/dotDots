"""Check runtime credential precedence, discovery, and private output."""

import importlib.util
from pathlib import Path
import stat
import tempfile
import unittest

from dotenv import dotenv_values

SCRIPT = Path(__file__).resolve().parents[2] / "Modules/nix/home/ai/agents/hermes/credentials/merge.py"
SPEC = importlib.util.spec_from_file_location("hermes_credentials", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class CredentialsTest(unittest.TestCase):
    def write(self, path, text):
        path.write_text(text)
        path.chmod(0o600)

    def test_order_literals_and_new_files(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            sources = root / "hermes"
            sources.mkdir()
            base = root / "hermes.env"
            self.write(base, "KEY=base\nBASE_ONLY=yes\nEMPTY=old\n")
            self.write(sources / ".env", "KEY=hidden\nTELEGRAM_BOT_TOKEN=fake\n")
            self.write(sources / "a.env", "KEY=first\nHF_TOKEN=fake\nEMPTY=\n")
            self.write(sources / "z.env", "KEY=last\nLITERAL='${KEEP} \\\\ path'\n")
            patterns = [str(base), str(sources / ".env"), str(sources / "*.env")]
            destination = root / "output" / "credentials.env"
            MODULE.merge(destination, patterns)
            values = dotenv_values(destination, interpolate=False)
            self.assertEqual(values["KEY"], "last")
            self.assertEqual(values["BASE_ONLY"], "yes")
            self.assertEqual(values["EMPTY"], "")
            self.assertEqual(values["TELEGRAM_BOT_TOKEN"], "fake")
            self.assertEqual(values["HF_TOKEN"], "fake")
            self.assertEqual(values["LITERAL"], dotenv_values(sources / "z.env", interpolate=False)["LITERAL"])
            self.assertEqual(stat.S_IMODE(destination.stat().st_mode), 0o600)
            self.write(sources / "new.env", "NEW_KEY=discovered\n")
            MODULE.merge(destination, patterns)
            self.assertEqual(dotenv_values(destination)["NEW_KEY"], "discovered")
            (sources / "new.env").unlink()
            MODULE.merge(destination, patterns)
            self.assertNotIn("NEW_KEY", dotenv_values(destination))

    def test_missing_sources_and_refusal_preserve_output(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            destination = root / "output.env"
            MODULE.merge(destination, [str(root / "missing.env"), str(root / "missing/*.env")])
            self.assertEqual(destination.read_text(), "")
            source = root / "source.env"
            self.write(source, "SECRET=fake\n")
            source.chmod(0o644)
            with self.assertRaises(ValueError):
                MODULE.merge(destination, [str(source)])
            self.assertEqual(destination.read_text(), "")
            source.chmod(0o600)
            link = root / "link.env"
            link.symlink_to(source)
            with self.assertRaises(ValueError):
                MODULE.merge(destination, [str(link)])


if __name__ == "__main__":
    unittest.main()
