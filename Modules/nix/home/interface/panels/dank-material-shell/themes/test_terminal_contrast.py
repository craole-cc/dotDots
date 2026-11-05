"""Regression checks for transparent terminal palette generation."""

import importlib.util
import random
import tempfile
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "terminal_contrast", Path(__file__).with_name("terminal-contrast.py")
)
theme = importlib.util.module_from_spec(spec)
spec.loader.exec_module(theme)


class TerminalContrastTests(unittest.TestCase):
    def test_all_colors_over_wallpaper_range(self):
        randomizer = random.Random(42)
        colors = ["#f9f9ff", "#c5daff", "#babcbe", "#e0e2e5", "#111318", "#183a6a"]
        colors += [
            theme.hex_color(tuple(randomizer.randrange(256) for _ in range(3)))
            for _ in range(100)
        ]
        for mode, background, opacity in (
            ("light", "#f9f9ff", 0.8),
            ("dark", "#111318", 0.75),
        ):
            bounds = theme.backgrounds(background, opacity)
            for color in colors:
                corrected = theme.readable(color, bounds, mode)
                self.assertEqual(theme.readable(corrected, bounds, mode), corrected)
                for wallpaper in (0, 64, 128, 192, 255):
                    surface = tuple(
                        opacity * channel + (1 - opacity) * wallpaper
                        for channel in theme.rgb(background)
                    )
                    self.assertGreaterEqual(
                        theme.contrast(theme.rgb(corrected), surface), 4.5
                    )

    def test_readable_colors_are_preserved(self):
        self.assertEqual(
            theme.readable("#494b51", theme.backgrounds("#f9f9ff", 0.8), "light"),
            "#494b51",
        )
        self.assertEqual(
            theme.readable("#f8fbff", theme.backgrounds("#111318", 0.75), "dark"),
            "#f8fbff",
        )

    def test_unachievable_contrast_fails(self):
        with self.assertRaisesRegex(ValueError, "Cannot achieve"):
            theme.readable("#777777", theme.backgrounds("#111318", 0), "dark")

    def test_renderers_share_all_sixteen_colors(self):
        data = {"colors": {}, "dank16": {f"color{index}": {} for index in range(16)}}
        for mode, background in (("dark", "#111318"), ("light", "#f9f9ff")):
            data["colors"][mode] = dict(
                background=background,
                on_surface="#888888",
                primary="#6687c4",
                primary_container=background,
            )
            for index in range(16):
                data["dank16"][f"color{index}"][mode] = "#778899"
        for mode in ("dark", "light"):
            opacities = dict(dark=0.75, light=0.8)
            outputs = theme.render(data, mode, opacities)
            expected = theme.palette(data, mode, opacities[mode])["ansi"]
            for index, color in enumerate(expected):
                self.assertIn(
                    f"color{index} {color}", outputs["kitty/dotdots-contrast.conf"]
                )
                self.assertIn(
                    f"palette = {index}={color}", outputs["ghostty/dotdots-contrast"]
                )
            foot = "\n".join(outputs["foot/dotdots-colors.ini"])
            self.assertIn("[colors-dark]", foot)
            self.assertIn("[colors-light]", foot)
            self.assertFalse(
                any(
                    "opacity" in line or "alpha=" in line
                    for lines in outputs.values()
                    for line in lines
                )
            )

    def test_atomic_write_is_idempotent_and_protects_symlinks(self):
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / "palette"
            self.assertTrue(theme.write_changed(target, "colors\n"))
            modified = target.stat().st_mtime_ns
            self.assertFalse(theme.write_changed(target, "colors\n"))
            self.assertEqual(target.stat().st_mtime_ns, modified)
            link = Path(directory) / "link"
            link.symlink_to(target)
            with self.assertRaisesRegex(ValueError, "symlink"):
                theme.write_changed(link, "replacement\n")
            self.assertEqual(target.read_text(), "colors\n")


if __name__ == "__main__":
    unittest.main()
