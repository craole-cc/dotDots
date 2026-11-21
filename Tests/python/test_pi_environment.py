"""Check Pi credential precedence and process handoff with synthetic values."""

import importlib.util
import os
import subprocess
import sys
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[2] / "Modules/nix/home/ai/agents/pi/environment.py"
SPEC = importlib.util.spec_from_file_location("pi_environment", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class PiEnvironmentTest(unittest.TestCase):
    def test_deepseek_process_receives_key_and_arguments(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            sources = [root / name for name in ["deepseek.env", "dsh.env", "config.env"]]
            for index, source in enumerate(sources):
                source.write_text(f"DEEPSEEK_API_KEY=synthetic-{index}\n")
            probe = (
                "import os, sys; "
                "assert os.environ['DEEPSEEK_API_KEY'] == 'synthetic-2'; "
                "assert sys.argv[1:] == ['headless', 'say hi']"
            )
            subprocess.run([
                sys.executable, str(SCRIPT), *(str(source) for source in sources),
                "--", sys.executable, "-c", probe, "headless", "say hi",
            ], check=True, capture_output=True)

    def test_precedence_literals_and_discovery(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            sources = root / "pi"
            sources.mkdir()
            base = root / "pi.env"
            base.write_text("KEY=base\nBASE_ONLY=yes\nEMPTY=old\n")
            (sources / ".env").write_text("KEY=hidden\nHIDDEN=yes\n")
            (sources / "z.env").write_text("KEY=last\nLITERAL='${KEEP} $(false)'\n")
            (sources / "a.env").write_text("KEY=first\nEMPTY=\nBARE\n")
            (sources / ".ignored.env").write_text("KEY=ignored\n")
            patterns = [str(base), str(sources / ".env"), str(sources / "*.env")]
            inherited = {"KEY": "inherited", "KEEP": "original", "BARE": "keep"}
            values = MODULE.load_environment(patterns, inherited)
            self.assertEqual(values, {
                "KEY": "last", "BASE_ONLY": "yes", "EMPTY": "",
                "HIDDEN": "yes", "LITERAL": "${KEEP} $(false)",
                "KEEP": "original", "BARE": "keep",
            })
            self.assertEqual(inherited["KEY"], "inherited")
            (sources / "new.env").write_text("NEW_KEY=discovered\n")
            self.assertEqual(MODULE.load_environment(patterns, {})["NEW_KEY"], "discovered")
            (sources / "new.env").unlink()
            self.assertNotIn("NEW_KEY", MODULE.load_environment(patterns, {}))

    def test_missing_sources(self):
        with tempfile.TemporaryDirectory() as directory:
            self.assertEqual(MODULE.load_environment([
                f"{directory}/missing.env", f"{directory}/missing/*.env",
            ], {"KEEP": "yes"}), {"KEEP": "yes"})

    def test_exec_preserves_arguments_and_inherited_environment(self):
        with patch.object(MODULE.sys, "argv", [
            "environment.py", "--", "/fake/bin/pi", "a prompt", "--continue",
        ]), patch.object(MODULE.os, "execve") as execute:
            MODULE.main()
            execute.assert_called_once_with(
                "/fake/bin/pi", ["/fake/bin/pi", "a prompt", "--continue"], dict(os.environ),
            )


if __name__ == "__main__":
    unittest.main()
