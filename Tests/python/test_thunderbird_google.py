"""Exercise private runtime setup without accessing a real profile or Google."""

import fcntl
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unittest


HELPER = Path(__file__).resolve().parents[2] / "Modules/nix/home/communication/thunderbird-google.py"


class GoogleSetupTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.profile = self.root / "profile"
        self.profile.mkdir()
        self.env = self.root / "google.env"
        self.env.write_text('GOOGLE_EMAIL=test@example.com\nGOOGLE_REAL_NAME="Test User"\n')
        self.env.chmod(0o600)
        self.prefs = self.profile / "prefs.js"
        self.prefs.write_text('user_pref("unrelated.setting", true);\n')

    def run_setup(self):
        return subprocess.run([sys.executable, str(HELPER), "--env", str(self.env),
                               "--profile", str(self.profile)], capture_output=True, text=True)

    def read_prefs(self):
        return {json.loads(match[1]): json.loads(match[2])
                for match in re.finditer(r'^user_pref\((".*?"), (.*)\);$',
                                         self.prefs.read_text(), re.MULTILINE)}

    def test_setup_preserves_settings_and_is_repeatable(self):
        original = self.prefs.read_text()
        result = self.run_setup()
        self.assertEqual(result.returncode, 0, result.stderr)
        prefs = self.read_prefs()
        self.assertTrue(prefs["unrelated.setting"])
        self.assertEqual(prefs["mail.server.dotdotsGoogle.authMethod"], 10)
        self.assertIn("https://apidata.googleusercontent.com/caldav/v2/test%40example.com/events/",
                      prefs.values())
        first = self.prefs.read_text()
        self.assertEqual(self.run_setup().returncode, 0)
        self.assertEqual(self.prefs.read_text(), first)
        backup = self.profile / "prefs.js.before-google-setup"
        self.assertEqual(backup.read_text(), original)
        self.assertEqual(backup.stat().st_mode & 0o777, 0o600)
        self.assertEqual(self.prefs.stat().st_mode & 0o777, 0o600)

    def test_existing_mail_and_calendar_are_reused(self):
        self.prefs.write_text('''user_pref("mail.identity.id1.useremail", "test@example.com");
user_pref("mail.identity.id1.smtpServer", "smtp1");
user_pref("mail.account.account1.identities", "id1,id2");
user_pref("mail.account.account1.server", "server1");
user_pref("mail.accountmanager.accounts", "account1,account2");
user_pref("calendar.registry.existing.uri", "https://apidata.googleusercontent.com/caldav/v2/test@example.com/events");
user_pref("calendar.list.sortOrder", "local existing");
''')
        result = self.run_setup()
        self.assertEqual(result.returncode, 0, result.stderr)
        prefs = self.read_prefs()
        self.assertEqual(prefs["mail.accountmanager.accounts"], "account1,account2")
        self.assertEqual(prefs["mail.account.account1.identities"], "id1,id2")
        self.assertEqual(prefs["calendar.list.sortOrder"], "local existing")
        self.assertEqual(prefs["calendar.registry.existing.type"], "caldav")
        self.assertFalse(any("dotdotsGoogle" in key for key in prefs))

    def test_multiple_calendars(self):
        with self.env.open("a") as stream:
            stream.write("GOOGLE_CALENDAR_IDS=test@example.com,shared@group.calendar.google.com\n")
        self.assertEqual(self.run_setup().returncode, 0)
        prefs = self.read_prefs()
        self.assertEqual(len([key for key in prefs if key.endswith(".uri")]), 2)

    def test_rejects_public_environment_without_changing_profile(self):
        original = self.prefs.read_text()
        self.env.chmod(0o644)
        self.assertNotEqual(self.run_setup().returncode, 0)
        self.assertEqual(self.prefs.read_text(), original)

    def test_rejects_locked_profile(self):
        original = self.prefs.read_text()
        (self.profile / "lock").symlink_to("missing-lock-target")
        self.assertNotEqual(self.run_setup().returncode, 0)
        self.assertEqual(self.prefs.read_text(), original)

    def test_rejects_invalid_email_without_echoing_it(self):
        self.env.write_text("GOOGLE_EMAIL=private-invalid-value\n")
        result = self.run_setup()
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("private-invalid-value", result.stderr)

    def test_rejects_active_posix_profile_lock(self):
        original = self.prefs.read_text()
        with (self.profile / ".parentlock").open("w") as lock:
            fcntl.lockf(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            self.assertNotEqual(self.run_setup().returncode, 0)
        self.assertEqual(self.prefs.read_text(), original)
        self.assertEqual(self.run_setup().returncode, 0)


if __name__ == "__main__":
    unittest.main()
