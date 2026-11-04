"""Generate terminal foregrounds with 4.5:1 contrast at the configured opacity."""

import argparse
import json
import os
from pathlib import Path
import tempfile


def rgb(color):
    return tuple(int(color.removeprefix("#")[index:index + 2], 16) for index in (0, 2, 4))


def hex_color(color):
    return "#" + "".join(f"{channel:02x}" for channel in color)


def luminance(color):
    channels = [channel / 255 for channel in color]
    linear = [channel / 12.92 if channel <= 0.04045 else ((channel + 0.055) / 1.055) ** 2.4
              for channel in channels]
    return sum(channel * weight for channel, weight in zip(linear, (0.2126, 0.7152, 0.0722)))


def contrast(first, second):
    high, low = sorted((luminance(first), luminance(second)), reverse=True)
    return (high + 0.05) / (low + 0.05)


def backgrounds(background, opacity):
    # Bound sRGB background compositing over any wallpaper, including blur.
    return [tuple(opacity * channel + (1 - opacity) * wallpaper for channel in rgb(background))
            for wallpaper in (0, 255)]


def readable(color, surfaces, mode):
    original = rgb(color)
    target = (0, 0, 0) if mode == "light" else (255, 255, 255)

    def passes(candidate):
        # Require the same luminance polarity across the entire background range.
        values = [luminance(surface) for surface in surfaces]
        value = luminance(candidate)
        polarity = value <= min(values) if mode == "light" else value >= max(values)
        return polarity and min(contrast(candidate, surface) for surface in surfaces) >= 4.5

    if passes(original):
        return hex_color(original)
    if not passes(target):
        raise ValueError(f"Cannot achieve 4.5:1 in {mode} mode at this background opacity")
    lower, upper = 0.0, 1.0
    result = target
    for _ in range(32):
        amount = (lower + upper) / 2
        candidate = tuple(round(channel + amount * (end - channel))
                          for channel, end in zip(original, target))
        if passes(candidate):
            upper, result = amount, candidate
        else:
            lower = amount
    return hex_color(result)


def palette(data, mode, opacity):
    colors = data["colors"][mode]
    surfaces = backgrounds(colors["background"], opacity)
    foreground = readable(colors["on_surface"], surfaces, mode)
    cursor = readable(colors["primary"], surfaces, mode)
    selection = colors["primary_container"]
    selection_fg = readable(foreground, [rgb(selection)], mode)
    ansi = [readable(data["dank16"][f"color{index}"][mode], surfaces, mode)
            for index in range(16)]
    return dict(background=colors["background"], foreground=foreground, cursor=cursor,
                selection=selection, selection_fg=selection_fg, ansi=ansi)


def render(data, mode, opacities):
    palettes = {variant: palette(data, variant, opacities[variant]) for variant in ("dark", "light")}
    active = palettes[mode]
    kitty = [f"foreground {active['foreground']}", f"background {active['background']}",
             f"cursor {active['cursor']}", f"cursor_text_color {active['background']}",
             f"selection_background {active['selection']}", f"selection_foreground {active['selection_fg']}"]
    kitty += [f"color{index} {color}" for index, color in enumerate(active["ansi"])]
    ghostty = [f"foreground = {active['foreground']}", f"background = {active['background']}",
               f"cursor-color = {active['cursor']}", f"cursor-text = {active['background']}",
               f"selection-background = {active['selection']}", f"selection-foreground = {active['selection_fg']}"]
    ghostty += [f"palette = {index}={color}" for index, color in enumerate(active["ansi"])]
    foot = []
    for variant, colors in palettes.items():
        foot += [f"[colors-{variant}]", f"foreground={colors['foreground'][1:]}",
                 f"background={colors['background'][1:]}",
                 f"selection-foreground={colors['selection_fg'][1:]}",
                 f"selection-background={colors['selection'][1:]}",
                 f"cursor={colors['background'][1:]} {colors['cursor'][1:]}"]
        foot += [f"{'regular' if index < 8 else 'bright'}{index % 8}={color[1:]}"
                 for index, color in enumerate(colors["ansi"])]
    return {"kitty/dotdots-contrast.conf": kitty, "ghostty/dotdots-contrast": ghostty,
            "foot/dotdots-colors.ini": foot}


def write_changed(path, content):
    if path.is_symlink():
        raise ValueError(f"Refusing to replace managed theme symlink: {path}")
    if path.exists() and path.read_text() == content:
        return False
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as output:
            temporary = Path(output.name)
            output.write(content)
        temporary.chmod(0o644)
        os.replace(temporary, path)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--config-home", type=Path, required=True)
    parser.add_argument("--mode", choices=("light", "dark"), required=True)
    parser.add_argument("--dark-opacity", type=float, required=True)
    parser.add_argument("--light-opacity", type=float, required=True)
    args = parser.parse_args()
    opacities = {"dark": args.dark_opacity, "light": args.light_opacity}
    if any(not 0 <= opacity <= 1 for opacity in opacities.values()):
        parser.error("Opacity must be between zero and one")
    if not args.source.exists():
        return  # DMS has not generated its first palette yet.
    data = json.loads(args.source.read_text())
    # Render and validate both modes before replacing any output.
    for relative, lines in render(data, args.mode, opacities).items():
        if write_changed(args.config_home / relative, "\n".join(lines) + "\n"):
            print(relative)


if __name__ == "__main__":
    main()
