"""Exercise the declarative Yazi migration against temporary homes."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[2] / "Modules/nix/home/environment/yazi/migrate-legacy-links.sh"


class YaziMigration(unittest.TestCase):
    def setUp(self):
        self.fixture = tempfile.TemporaryDirectory(prefix="yazi migration ")
        self.addCleanup(self.fixture.cleanup)
        self.root = Path(self.fixture.name)
        self.target = self.root / "config"
        self.source = self.root / "repository"
        self.target.mkdir()
        self.source.mkdir()
        for name in ["config.toml", "keymap.toml"]:
            (self.source / name).write_text("Repository content\n")

    def run_migration(self, dry_run="", extension="hm-backup"):
        subprocess.run(["bash", str(SCRIPT), str(self.target), str(self.source), dry_run],
                       env={**os.environ, "HOME_MANAGER_BACKUP_EXT": extension},
                       check=True, capture_output=True, text=True)

    def test_backup_preserves_links_sources_and_existing_backups(self):
        for target, source in [("yazi.toml", "config.toml"), ("keymap.toml", "keymap.toml")]:
            (self.target / target).symlink_to(self.source / source)
        (self.target / "yazi.toml.hm-backup").write_text("Existing backup")
        (self.target / "yazi.toml.hm-backup.1").symlink_to(self.root / "missing")
        self.run_migration()
        self.run_migration()  # Activation can be retried safely.
        self.assertFalse((self.target / "yazi.toml").is_symlink())
        self.assertEqual((self.target / "yazi.toml.hm-backup.2").readlink(), self.source / "config.toml")
        self.assertEqual((self.target / "keymap.toml.hm-backup").readlink(), self.source / "keymap.toml")
        self.assertEqual((self.target / "yazi.toml.hm-backup").read_text(), "Existing backup")
        self.assertTrue((self.target / "yazi.toml.hm-backup.1").is_symlink())
        self.assertEqual((self.source / "config.toml").read_text(), "Repository content\n")

    def test_unrelated_files_and_links_are_untouched(self):
        (self.target / "yazi.toml").write_text("User content")
        (self.target / "keymap.toml").symlink_to(self.root / "foreign")
        self.run_migration()
        self.assertEqual((self.target / "yazi.toml").read_text(), "User content")
        self.assertEqual((self.target / "keymap.toml").readlink(), self.root / "foreign")
        self.assertEqual(len(list(self.target.iterdir())), 2)

    def test_dry_run_changes_nothing(self):
        (self.target / "yazi.toml").symlink_to(self.source / "config.toml")
        self.run_migration(dry_run="echo")
        self.assertTrue((self.target / "yazi.toml").is_symlink())
        self.assertEqual(len(list(self.target.iterdir())), 1)

    def test_custom_backup_extension(self):
        (self.target / "yazi.toml").symlink_to(self.source / "config.toml")
        self.run_migration(extension="custom-backup")
        self.assertTrue((self.target / "yazi.toml.custom-backup").is_symlink())


if __name__ == "__main__":
    unittest.main()
