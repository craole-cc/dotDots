"""Apply dotDots appearance at startup and refresh the live Qt palette."""

import argparse
import configparser
import io
import json
import os
import shutil
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path

import json5


def write_file(path, content, backup=False, force=False):
    if path.is_symlink():
        raise RuntimeError(f"Refusing to replace managed symlink: {path}")
    if not force and path.exists() and path.read_text() == content:
        return False
    path.parent.mkdir(parents=True, exist_ok=True)
    saved = path.with_name(path.name + ".before-dotdots")
    if backup and path.exists() and not saved.exists():
        shutil.copy2(path, saved)
    descriptor, temporary = tempfile.mkstemp(dir=path.parent, prefix=".appearance-")
    try:
        with os.fdopen(descriptor, "w") as output:
            output.write(content)
        os.replace(temporary, path)
    finally:
        Path(temporary).unlink(missing_ok=True)
    return True


def dc_colour(value):
    """Double Commander stores colours as decimal BGR values."""
    colour = value.removeprefix("#")
    if len(colour) != 6:
        raise ValueError(f"Expected RGB colour, got {value!r}")
    return int(colour[4:6] + colour[2:4] + colour[0:2], 16)


def apply_colours(directory, palettes):
    path = directory / "colors.json"
    document = json5.loads(path.read_text()) if path.exists() else {}
    styles = document.setdefault("Styles", [])
    for mode, palette in palettes.items():
        name = mode.capitalize()
        style = next((entry for entry in styles if entry.get("Name") == name), None)
        if style is None:
            style = {"Name": name}
            styles.append(style)
        colours = {key: dc_colour(value) for key, value in palette.items()}
        groups = {
            "FilePanel": {
                "ForeColor": "foreground",
                "BackColor": "background",
                "BackColor2": "surface",
                "MarkColor": "primary",
                "CursorColor": "primary",
                "CursorText": "onPrimary",
                "CursorBorderColor": "primary",
                "GridLine": "outline",
                "InactiveCursorColor": "surface",
                "InactiveMarkColor": "primary",
            },
            "Path": {
                "ActiveColor": "primary",
                "ActiveFontColor": "onPrimary",
                "InactiveColor": "surface",
                "InactiveFontColor": "foreground",
            },
            "Log": {
                "InfoColor": "link",
                "ErrorColor": "error",
                "SuccessColor": "success",
            },
            "FreeSpaceIndicator": {
                "ForeColor": "primary",
                "BackColor": "surface",
                "ThresholdForeColor": "error",
            },
        }
        for group, fields in groups.items():
            style.setdefault(group, {}).update(
                {key: colours[role] for key, role in fields.items()}
            )
    write_file(path, json.dumps(document, indent=2) + "\n", backup=True)


def apply_fonts(directory, fonts):
    path = directory / "doublecmd.xml"
    if path.exists():
        tree = ET.parse(path)
        root = tree.getroot()
    else:
        root = ET.Element("doublecmd")
    section = root.find("Fonts")
    if section is None:
        section = ET.SubElement(root, "Fonts")
    names = [
        "Main",
        "Editor",
        "Viewer",
        "ViewerBook",
        "Log",
        "Console",
        "PathEdit",
        "FunctionButtons",
        "SearchResults",
        "TreeViewMenu",
        "StatusBar",
    ]
    for name in names:
        element = section.find(name)
        if element is None:
            element = ET.SubElement(section, name)
        font = fonts[
            "fixed" if name in {"Editor", "Viewer", "Log", "Console"} else "general"
        ]
        for field, value in {"Name": font["name"], "Size": font["size"]}.items():
            child = element.find(field)
            if child is None:
                child = ET.SubElement(element, field)
            child.text = str(value)
    for element in root.findall("./ColumnsSets/ColumnsSet/Columns/Column/Font"):
        name = element.find("Name")
        if name is not None:
            name.text = fonts["general"]["name"]
        size = element.find("Size")
        if size is not None:
            size.text = str(fonts["general"]["size"])
    write_file(
        path,
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        + ET.tostring(root, encoding="unicode"),
        backup=True,
    )


def apply_qt(directory, settings):
    profile = directory.parent / "qt5ct"
    palette = settings["palettes"][settings["mode"]]
    colour_path = profile / "colors/dotdots-doublecmd.conf"
    # QPalette roles, in Qt5's serialisation order.
    roles = [
        "foreground",
        "surface",
        "surface",
        "surface",
        "outline",
        "outline",
        "foreground",
        "onPrimary",
        "foreground",
        "background",
        "background",
        "outline",
        "primary",
        "onPrimary",
        "link",
        "primary",
        "surface",
        "background",
        "surface",
        "foreground",
        "outline",
    ]
    active = ", ".join(palette[role] for role in roles)
    disabled = ", ".join(
        palette["outline"] if role == "foreground" else palette[role] for role in roles
    )
    palette_changed = write_file(
        colour_path,
        f"[ColorScheme]\nactive_colors={active}\ninactive_colors={active}\ndisabled_colors={disabled}\n",
    )
    config = configparser.ConfigParser()
    config.read(profile / "qt5ct.conf")
    if not config.has_section("Appearance"):
        config.add_section("Appearance")
    config["Appearance"].update(
        {
            "style": "Fusion",
            "custom_palette": "true",
            "color_scheme_path": str(colour_path),
            "icon_theme": settings["icons"][settings["mode"]],
            "standard_dialogs": "default",
        }
    )
    if not config.has_section("Fonts"):
        config.add_section("Fonts")
    config["Fonts"].update(
        {
            role: f'"{font["name"]},{font["size"]},-1,5,50,0,0,0,0,0"'
            for role, font in settings["fonts"].items()
        }
    )
    output = io.StringIO()
    config.write(output, space_around_delimiters=False)
    # Qt5ct watches this directory, not the nested colour-scheme directory.
    # Replacing its config also notifies it when only the palette has changed.
    write_file(
        profile / "qt5ct.conf", output.getvalue(), backup=True, force=palette_changed
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", type=Path, required=True)
    parser.add_argument("--defaults", type=Path, required=True)
    parser.add_argument("--palette", type=Path, required=True)
    parser.add_argument("--live", action="store_true")
    arguments = parser.parse_args()
    settings = json.loads(arguments.defaults.read_text())
    if arguments.palette.exists():
        generated = json.loads(arguments.palette.read_text())
        if generated["mode"] not in {"light", "dark"}:
            raise ValueError("DMS palette must select light or dark mode")
        roles = {
            "foreground": "on_surface",
            "background": "background",
            "surface": "surface_container",
            "primary": "primary",
            "onPrimary": "on_primary",
            "outline": "outline",
            "error": "error",
        }
        settings["mode"] = generated["mode"]
        settings["palettes"] = {
            mode: {
                **{
                    role: generated["colors"][mode][name]
                    for role, name in roles.items()
                },
                "success": generated["dank16"]["color2"][mode],
                "link": generated["dank16"]["color4"][mode],
            }
            for mode in ("light", "dark")
        }
    if not arguments.live:
        apply_colours(arguments.config, settings["palettes"])
        apply_fonts(arguments.config, settings["fonts"])
    apply_qt(arguments.config, settings)


if __name__ == "__main__":
    main()
