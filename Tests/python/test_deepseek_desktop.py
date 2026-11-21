"""Check the private URL handoff without launching a browser or provider."""

import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[2] / "Modules/nix/home/ai/agents/deepseek/desktop.py"
SPEC = importlib.util.spec_from_file_location("deepseek_desktop", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class DesktopTest(unittest.TestCase):
    def test_failed_service_has_concise_error(self):
        with patch.dict(MODULE.os.environ, {"XDG_RUNTIME_DIR": "/fake"}), \
                patch.object(MODULE.sys, "argv", ["desktop.py", "/systemctl", "/chromium", "3081"]), \
                patch.object(MODULE.subprocess, "run", side_effect=MODULE.subprocess.CalledProcessError(1, "systemctl")):
            with self.assertRaisesRegex(SystemExit, "Could not start DeepSeek"):
                MODULE.main()

    def test_owned_url_only(self):
        self.assertIsNone(MODULE.startup_url("dsh web: http://example.org:3081/", "3081"))
        self.assertIsNone(MODULE.startup_url("dsh web: http://127.0.0.1:3080/", "3081"))
        self.assertEqual(MODULE.startup_url(
            "dsh web: http://127.0.0.1:3081/?token=synthetic\nother output", "3081",
        ), "http://127.0.0.1:3081/?token=synthetic")

    def test_app_handoff_and_unauthenticated_probe(self):
        with tempfile.TemporaryDirectory() as directory:
            runtime = Path(directory) / "deepseek-web"
            runtime.mkdir()
            url = "http://127.0.0.1:3081/?token=synthetic"
            (runtime / "startup.log").write_text(f"dsh web: {url}\n")
            with patch.dict(MODULE.os.environ, {
                "XDG_RUNTIME_DIR": directory, "XDG_CONFIG_HOME": directory,
            }), patch.object(MODULE.sys, "argv", ["desktop.py", "/systemctl", "/chromium", "3081"]), \
                    patch.object(MODULE.subprocess, "run") as run, \
                    patch.object(MODULE.urllib.request, "build_opener") as opener, \
                    patch.object(MODULE.os, "execv", side_effect=SystemExit) as execute:
                with self.assertRaises(SystemExit):
                    MODULE.main()
                run.assert_called_once_with([
                    "/systemctl", "--user", "start", "deepseek-web.service",
                ], check=True)
                opener.return_value.open.assert_called_once_with("http://127.0.0.1:3081/", timeout=1)
                self.assertEqual(execute.call_args.args[1][-1], f"--app={url}")


if __name__ == "__main__":
    unittest.main()
