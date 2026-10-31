#!/usr/bin/env rust-script
//! Apply dotDots appearance at startup and refresh the live Qt palette.
//!
//! ```cargo
//! [dependencies]
//! json5 = "0.4"
//! serde_json = { version = "1", features = ["preserve_order"] }
//! tempfile = "3"
//! xmltree = { version = "0.11", features = ["attribute-order"] }
//! ```

use std::collections::BTreeMap;
use std::env;
use std::error::Error;
use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};
use std::process::ExitCode;

use serde_json::{json, Map, Value};
use xmltree::{Element, EmitterConfig, XMLNode};

type Result<T> = std::result::Result<T, Box<dyn Error>>;

fn write_file(path: &Path, content: &[u8], backup: bool, force: bool) -> Result<bool> {
    if fs::symlink_metadata(path).is_ok_and(|metadata| metadata.file_type().is_symlink()) {
        return Err(format!("Refusing to replace managed symlink: {}", path.display()).into());
    }
    if !force && path.exists() && fs::read(path)? == content {
        return Ok(false);
    }
    let parent = path.parent().ok_or("Configuration file has no parent")?;
    fs::create_dir_all(parent)?;
    let saved = path.with_file_name(format!(
        "{}.before-dotdots",
        path.file_name()
            .ok_or("Configuration file has no name")?
            .to_string_lossy()
    ));
    if backup && path.exists() && !saved.exists() {
        fs::copy(path, saved)?;
    }
    let mut temporary = tempfile::Builder::new()
        .prefix(".appearance-")
        .tempfile_in(parent)?;
    temporary.write_all(content)?;
    temporary.persist(path)?;
    Ok(true)
}

fn text(value: &Value) -> Result<&str> {
    value
        .as_str()
        .ok_or_else(|| format!("Expected text, got {value}").into())
}

fn dc_colour(value: &Value) -> Result<u32> {
    let colour = text(value)?.trim_start_matches('#');
    if colour.len() != 6 || !colour.bytes().all(|byte| byte.is_ascii_hexdigit()) {
        return Err(format!("Expected RGB colour, got {value}").into());
    }
    Ok(u32::from_str_radix(
        &format!("{}{}{}", &colour[4..6], &colour[2..4], &colour[0..2]),
        16,
    )?)
}

fn apply_colours(directory: &Path, palettes: &Value) -> Result<()> {
    let path = directory.join("colors.json");
    let mut document: Value = if path.exists() {
        json5::from_str(&fs::read_to_string(&path)?)?
    } else {
        json!({"Styles": []})
    };
    let styles = document
        .as_object_mut()
        .ok_or("Colours must be an object")?
        .entry("Styles")
        .or_insert_with(|| json!([]))
        .as_array_mut()
        .ok_or("Styles must be an array")?;
    let groups: &[(&str, &[(&str, &str)])] = &[
        (
            "FilePanel",
            &[
                ("ForeColor", "foreground"),
                ("BackColor", "background"),
                ("BackColor2", "surface"),
                ("MarkColor", "primary"),
                ("CursorColor", "primary"),
                ("CursorText", "onPrimary"),
                ("CursorBorderColor", "primary"),
                ("GridLine", "outline"),
                ("InactiveCursorColor", "surface"),
                ("InactiveMarkColor", "primary"),
            ],
        ),
        (
            "Path",
            &[
                ("ActiveColor", "primary"),
                ("ActiveFontColor", "onPrimary"),
                ("InactiveColor", "surface"),
                ("InactiveFontColor", "foreground"),
            ],
        ),
        (
            "Log",
            &[
                ("InfoColor", "link"),
                ("ErrorColor", "error"),
                ("SuccessColor", "success"),
            ],
        ),
        (
            "FreeSpaceIndicator",
            &[
                ("ForeColor", "primary"),
                ("BackColor", "surface"),
                ("ThresholdForeColor", "error"),
            ],
        ),
    ];
    for (mode, name) in [("light", "Light"), ("dark", "Dark")] {
        let index = styles
            .iter()
            .position(|style| style["Name"] == name)
            .unwrap_or_else(|| {
                styles.push(json!({"Name": name}));
                styles.len() - 1
            });
        for (group, fields) in groups {
            let style = styles[index]
                .as_object_mut()
                .ok_or("Style must be an object")?;
            let values = style
                .entry(*group)
                .or_insert_with(|| json!({}))
                .as_object_mut()
                .ok_or("Colour group must be an object")?;
            for (field, role) in *fields {
                values.insert(
                    (*field).to_owned(),
                    json!(dc_colour(&palettes[mode][role])?),
                );
            }
        }
    }
    let output = serde_json::to_string_pretty(&document)? + "\n";
    write_file(&path, output.as_bytes(), true, false)?;
    Ok(())
}

fn child_mut<'a>(element: &'a mut Element, name: &str) -> &'a mut Element {
    let index = element
        .children
        .iter()
        .position(|child| {
            child
                .as_element()
                .is_some_and(|element| element.name == name)
        })
        .unwrap_or_else(|| {
            element.children.push(XMLNode::Element(Element::new(name)));
            element.children.len() - 1
        });
    element.children[index]
        .as_mut_element()
        .expect("Element child")
}

fn set_text(element: &mut Element, name: &str, value: String) {
    child_mut(element, name).children = vec![XMLNode::Text(value)];
}

fn font_size(font: &Value) -> Result<String> {
    let size = font["size"]
        .as_u64()
        .ok_or("Font size must be a positive integer")?;
    if size == 0 {
        return Err("Font size must be positive".into());
    }
    Ok(size.to_string())
}

fn apply_fonts(directory: &Path, fonts: &Value) -> Result<()> {
    let path = directory.join("doublecmd.xml");
    let mut root = if path.exists() {
        Element::parse(fs::File::open(&path)?)?
    } else {
        Element::new("doublecmd")
    };
    let section = child_mut(&mut root, "Fonts");
    for name in [
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
    ] {
        let font = &fonts[if ["Editor", "Viewer", "Log", "Console"].contains(&name) {
            "fixed"
        } else {
            "general"
        }];
        let element = child_mut(section, name);
        set_text(element, "Name", text(&font["name"])?.to_owned());
        set_text(element, "Size", font_size(font)?);
    }
    if let Some(sets) = root.get_mut_child("ColumnsSets") {
        for set in sets
            .children
            .iter_mut()
            .filter_map(XMLNode::as_mut_element)
            .filter(|element| element.name == "ColumnsSet")
        {
            if let Some(columns) = set.get_mut_child("Columns") {
                for column in columns
                    .children
                    .iter_mut()
                    .filter_map(XMLNode::as_mut_element)
                    .filter(|element| element.name == "Column")
                {
                    if let Some(font) = column.get_mut_child("Font") {
                        if font.get_child("Name").is_some() {
                            set_text(font, "Name", text(&fonts["general"]["name"])?.to_owned());
                        }
                        if font.get_child("Size").is_some() {
                            set_text(font, "Size", font_size(&fonts["general"])?);
                        }
                    }
                }
            }
        }
    }
    let mut output = Vec::new();
    root.write_with_config(&mut output, EmitterConfig::new().perform_indent(true))?;
    write_file(&path, &output, true, false)?;
    Ok(())
}

fn update_ini(input: &str, updates: &BTreeMap<&str, BTreeMap<&str, String>>) -> String {
    let mut pending = updates.clone();
    let mut section = String::new();
    let mut lines = Vec::new();
    for line in input.lines() {
        let trimmed = line.trim();
        if trimmed.starts_with('[') && trimmed.ends_with(']') {
            if let Some(fields) = pending.remove(section.as_str()) {
                lines.extend(
                    fields
                        .into_iter()
                        .map(|(key, value)| format!("{key}={value}")),
                );
            }
            section = trimmed[1..trimmed.len() - 1].to_owned();
        } else if let Some((key, _)) = trimmed.split_once('=') {
            if let Some(value) = pending
                .get_mut(section.as_str())
                .and_then(|fields| fields.remove(key.trim()))
            {
                lines.push(format!("{}={value}", key.trim()));
                continue;
            }
        }
        lines.push(line.to_owned());
    }
    if let Some(fields) = pending.remove(section.as_str()) {
        lines.extend(
            fields
                .into_iter()
                .map(|(key, value)| format!("{key}={value}")),
        );
    }
    for (section, fields) in pending {
        lines.push(format!("\n[{section}]"));
        lines.extend(
            fields
                .into_iter()
                .map(|(key, value)| format!("{key}={value}")),
        );
    }
    lines.join("\n") + "\n"
}

fn apply_qt(directory: &Path, settings: &Value) -> Result<()> {
    let profile = directory
        .parent()
        .ok_or("Double Commander directory has no parent")?
        .join("qt5ct");
    let mode = text(&settings["mode"])?;
    let palette = &settings["palettes"][mode];
    let colour_path = profile.join("colors/dotdots-doublecmd.conf");
    // QPalette roles, in Qt5's serialisation order.
    let roles = [
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
    ];
    let active = roles
        .iter()
        .map(|role| text(&palette[*role]))
        .collect::<Result<Vec<_>>>()?
        .join(", ");
    let disabled = roles
        .iter()
        .map(|role| {
            text(
                &palette[if *role == "foreground" {
                    "outline"
                } else {
                    role
                }],
            )
        })
        .collect::<Result<Vec<_>>>()?
        .join(", ");
    let colours = format!("[ColorScheme]\nactive_colors={active}\ninactive_colors={active}\ndisabled_colors={disabled}\n");
    let palette_changed = write_file(&colour_path, colours.as_bytes(), false, false)?;
    let mut font_values = BTreeMap::new();
    for role in ["general", "fixed"] {
        let font = &settings["fonts"][role];
        font_values.insert(
            role,
            format!(
                "\"{},{},-1,5,50,0,0,0,0,0\"",
                text(&font["name"])?,
                font_size(font)?
            ),
        );
    }
    let updates = BTreeMap::from([
        (
            "Appearance",
            BTreeMap::from([
                ("style", "Fusion".to_owned()),
                ("custom_palette", "true".to_owned()),
                (
                    "color_scheme_path",
                    colour_path.to_string_lossy().into_owned(),
                ),
                ("icon_theme", text(&settings["icons"][mode])?.to_owned()),
                ("standard_dialogs", "default".to_owned()),
            ]),
        ),
        ("Fonts", font_values),
    ]);
    let path = profile.join("qt5ct.conf");
    let existing = if path.exists() {
        fs::read_to_string(&path)?
    } else {
        String::new()
    };
    let output = update_ini(&existing, &updates);
    // Replacing this file notifies Qt5ct even when only the nested palette changed.
    write_file(&path, output.as_bytes(), true, palette_changed)?;
    Ok(())
}

fn run() -> Result<()> {
    let mut arguments = env::args_os().skip(1);
    let mut paths = BTreeMap::new();
    let mut live = false;
    while let Some(argument) = arguments.next() {
        match argument.to_str() {
            Some("--live") => live = true,
            Some(option @ ("--config" | "--defaults" | "--palette")) => {
                paths.insert(
                    option.to_owned(),
                    PathBuf::from(arguments.next().ok_or("Missing path argument")?),
                );
            }
            _ => return Err(format!("Unknown argument: {}", argument.to_string_lossy()).into()),
        }
    }
    let directory = paths.get("--config").ok_or("--config is required")?;
    let defaults = paths.get("--defaults").ok_or("--defaults is required")?;
    let source = paths.get("--palette").ok_or("--palette is required")?;
    let mut settings: Value = serde_json::from_str(&fs::read_to_string(defaults)?)?;
    if source.exists() {
        let generated: Value = serde_json::from_str(&fs::read_to_string(source)?)?;
        settings["mode"] = generated["mode"].clone();
        let mut palettes = Map::new();
        for mode in ["light", "dark"] {
            let mut palette = Map::new();
            for (role, name) in [
                ("foreground", "on_surface"),
                ("background", "background"),
                ("surface", "surface_container"),
                ("primary", "primary"),
                ("onPrimary", "on_primary"),
                ("outline", "outline"),
                ("error", "error"),
            ] {
                palette.insert(role.to_owned(), generated["colors"][mode][name].clone());
            }
            palette.insert(
                "success".to_owned(),
                generated["dank16"]["color2"][mode].clone(),
            );
            palette.insert(
                "link".to_owned(),
                generated["dank16"]["color4"][mode].clone(),
            );
            palettes.insert(mode.to_owned(), Value::Object(palette));
        }
        settings["palettes"] = Value::Object(palettes);
    }
    if !matches!(text(&settings["mode"])?, "light" | "dark") {
        return Err("DMS palette must select light or dark mode".into());
    }
    if !live {
        apply_colours(directory, &settings["palettes"])?;
        apply_fonts(directory, &settings["fonts"])?;
    }
    apply_qt(directory, &settings)
}

fn main() -> ExitCode {
    match run() {
        Ok(()) => ExitCode::SUCCESS,
        Err(error) => {
            eprintln!("Double Commander appearance: {error}");
            ExitCode::FAILURE
        }
    }
}
