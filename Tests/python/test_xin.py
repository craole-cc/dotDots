"""Exercise xin against fake backends; never update, clean, or activate Nix."""

import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


class XinTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.workspace = tempfile.TemporaryDirectory(prefix="xin-tests-")
        cls.root = Path(cls.workspace.name)
        cls.binary = cls.root / "xin"
        source = Path(__file__).resolve().parents[2] / "Libraries/rust/src/xin.rs"
        subprocess.run(
            ["rustc", "--edition", "2024", str(source), "-o", str(cls.binary)],
            check=True,
        )

    @classmethod
    def tearDownClass(cls):
        cls.workspace.cleanup()

    def setUp(self):
        self.workspace = tempfile.TemporaryDirectory(dir=self.root)
        self.addCleanup(self.workspace.cleanup)
        self.case = Path(self.workspace.name)
        self.checkout = self.case / "flake with spaces"
        self.checkout.mkdir()
        (self.checkout / "flake.nix").touch()
        self.bin = self.case / "bin"
        self.bin.mkdir()
        self.log = self.case / "calls.jsonl"
        self.environment = {
            **os.environ,
            "PATH": str(self.bin),
            "DOTS": str(self.checkout),
            "USER": "test.user",
            "XIN_TEST_LOG": str(self.log),
        }

    def backend(self, name, code=0):
        script = self.bin / name
        script.write_text(
            f"#!{sys.executable}\n"
            "import json, os, sys\n"
            "with open(os.environ['XIN_TEST_LOG'], 'a') as log:\n"
            "    log.write(json.dumps([os.path.basename(sys.argv[0]), *sys.argv[1:]]) + '\\n')\n"
            f"sys.exit({code})\n"
        )
        script.chmod(0o755)

    def run_xin(self, *args):
        return subprocess.run(
            [str(self.binary), *args],
            env=self.environment,
            capture_output=True,
            text=True,
            check=False,
        )

    def calls(self):
        return (
            [json.loads(line) for line in self.log.read_text().splitlines()]
            if self.log.exists()
            else []
        )

    def test_nh_cleanup_works_without_a_flake(self):
        self.backend("nh")
        self.environment["DOTS"] = str(self.case / "missing")
        result = self.run_xin("--clean")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls(), [["nh", "clean", "all"]])

    def test_missing_nh_uses_nix_gc(self):
        self.backend("nix")
        result = self.run_xin("--clean")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls(), [["nix", "store", "gc"]])

    def test_targeted_update_preserves_argument_boundaries(self):
        self.backend("nix")
        result = self.run_xin("--update", "hermes", "buufIcons")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.calls(),
            [
                [
                    "nix",
                    "flake",
                    "update",
                    "--flake",
                    str(self.checkout),
                    "hermes",
                    "buufIcons",
                    "--show-trace",
                ]
            ],
        )

    def test_release_snapshot_updates_only_after_a_successful_update(self):
        metadata = self.checkout / "Modules/nix/home/ai/agents/hermes/release.json"
        metadata.parent.mkdir(parents=True)
        metadata.write_text("original\n")
        git = self.bin / "git"
        git.write_text(f"#!{sys.executable}\nprint('{'a' * 40}\\trefs/tags/v0.23.0')\n")
        git.chmod(0o755)
        self.backend("nix", code=7)
        result = self.run_xin("--update", "hermes")
        self.assertEqual(result.returncode, 7, result.stderr)
        self.assertEqual(metadata.read_text(), "original\n")
        self.backend("nix")
        result = self.run_xin("--update", "hermes")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(metadata.read_text())["tag_name"], "v0.23.0")

    def test_default_home_context_uses_hostname_and_user(self):
        self.backend("nix")
        hostname = self.bin / "hostname"
        hostname.write_text(f"#!{sys.executable}\nprint('test.host')\n")
        hostname.chmod(0o755)
        result = self.run_xin("--repl-home")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.calls(),
            [
                [
                    "nix",
                    "repl",
                    str(self.checkout)
                    + '#nixosConfigurations."test.host".config.home-manager.users."test.user"',
                    "--show-trace",
                ]
            ],
        )

    def test_no_trace_and_backend_exit_code(self):
        self.backend("nix", code=7)
        result = self.run_xin("--check", "--no-trace")
        self.assertEqual(result.returncode, 7)
        self.assertEqual(self.calls(), [["nix", "flake", "check", str(self.checkout)]])

    def test_dry_run_does_not_execute_a_backend(self):
        self.backend("nh")
        result = self.run_xin("--switch", "--host", "test.host", "--dry-run")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls(), [])
        self.assertIn("'nh' 'os' 'switch'", result.stderr)

    def test_rebuild_fallback_and_nh_trace_forwarding(self):
        self.backend("nixos-rebuild")
        result = self.run_xin("--build", "--host", "test.host")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.calls()[0],
            [
                "nixos-rebuild",
                "build",
                "--flake",
                str(self.checkout) + '#"test.host"',
                "--show-trace",
            ],
        )
        self.backend("nh")
        result = self.run_xin("--build", "--host", "test.host", "--", "--keep-going")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.calls()[-1],
            [
                "nh",
                "os",
                "build",
                str(self.checkout),
                "--hostname",
                "test.host",
                "--",
                "--show-trace",
                "--keep-going",
            ],
        )


if __name__ == "__main__":
    unittest.main()
