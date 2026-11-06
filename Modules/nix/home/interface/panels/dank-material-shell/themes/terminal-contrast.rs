#!/usr/bin/env rust-script
//! Generate terminal foregrounds with 4.5:1 contrast at configured opacity.
//!
//! ```cargo
//! [dependencies]
//! serde_json = "1"
//! ```

use std::env;
use std::fs::{self, OpenOptions};
use std::io::Write;
use std::os::unix::fs::{OpenOptionsExt, PermissionsExt};
use std::path::{Path, PathBuf};
use std::process::ExitCode;
use std::sync::atomic::{AtomicU64, Ordering};

use serde_json::Value;

const TARGET_CONTRAST: f64 = 4.5;
static TEMP_SEQUENCE: AtomicU64 = AtomicU64::new(0);

type Rgb = [u8; 3];
type Surface = [f64; 3];

fn rgb(color: &str) -> Result<Rgb, String> {
    let hex = color.strip_prefix('#').unwrap_or(color);
    if hex.len() != 6 {
        return Err(format!("Expected a six-digit hex color, got {color:?}"));
    }
    let mut result = [0; 3];
    for (index, channel) in result.iter_mut().enumerate() {
        *channel = u8::from_str_radix(&hex[index * 2..index * 2 + 2], 16)
            .map_err(|error| format!("Invalid hex color {color:?}: {error}"))?;
    }
    Ok(result)
}

fn hex_color(color: Rgb) -> String {
    format!("#{:02x}{:02x}{:02x}", color[0], color[1], color[2])
}

fn luminance(color: [f64; 3]) -> f64 {
    let linear = color.map(|channel| {
        let value = channel / 255.0;
        if value <= 0.04045 {
            value / 12.92
        } else {
            ((value + 0.055) / 1.055).powf(2.4)
        }
    });
    linear[0] * 0.2126 + linear[1] * 0.7152 + linear[2] * 0.0722
}

fn contrast(first: [f64; 3], second: [f64; 3]) -> f64 {
    let first = luminance(first);
    let second = luminance(second);
    (first.max(second) + 0.05) / (first.min(second) + 0.05)
}

fn backgrounds(background: &str, opacity: f64) -> Result<[Surface; 2], String> {
    let background = rgb(background)?;
    Ok([0.0, 255.0].map(|wallpaper| {
        background.map(|channel| opacity * f64::from(channel) + (1.0 - opacity) * wallpaper)
    }))
}

fn readable(color: &str, surfaces: &[Surface], mode: &str) -> Result<String, String> {
    let original = rgb(color)?;
    let target = if mode == "light" {
        [0, 0, 0]
    } else {
        [255, 255, 255]
    };
    let passes = |candidate: Rgb| {
        let value = luminance(candidate.map(f64::from));
        let surface_luminances: Vec<f64> =
            surfaces.iter().map(|surface| luminance(*surface)).collect();
        let polarity = if mode == "light" {
            value
                <= surface_luminances
                    .iter()
                    .copied()
                    .fold(f64::INFINITY, f64::min)
        } else {
            value
                >= surface_luminances
                    .iter()
                    .copied()
                    .fold(f64::NEG_INFINITY, f64::max)
        };
        polarity
            && surfaces
                .iter()
                .all(|surface| contrast(candidate.map(f64::from), *surface) >= TARGET_CONTRAST)
    };

    if passes(original) {
        return Ok(hex_color(original));
    }
    if !passes(target) {
        return Err(format!(
            "Cannot achieve 4.5:1 in {mode} mode at this background opacity"
        ));
    }

    let (mut lower, mut upper) = (0.0, 1.0);
    let mut result = target;
    for _ in 0..32 {
        let amount = (lower + upper) / 2.0;
        let candidate = std::array::from_fn(|index| {
            let start = f64::from(original[index]);
            let end = f64::from(target[index]);
            (start + amount * (end - start)).round_ties_even() as u8
        });
        if passes(candidate) {
            upper = amount;
            result = candidate;
        } else {
            lower = amount;
        }
    }
    Ok(hex_color(result))
}

fn string_at<'a>(value: &'a Value, path: &[&str]) -> Result<&'a str, String> {
    let mut current = value;
    for segment in path {
        current = current
            .get(*segment)
            .ok_or_else(|| format!("Missing JSON field {}", path.join(".")))?;
    }
    current
        .as_str()
        .ok_or_else(|| format!("JSON field {} must be a string", path.join(".")))
}

fn palette(data: &Value, mode: &str, opacity: f64) -> Result<Value, String> {
    let background = string_at(data, &["colors", mode, "background"])?;
    let on_surface = string_at(data, &["colors", mode, "on_surface"])?;
    let primary = string_at(data, &["colors", mode, "primary"])?;
    let primary_container = string_at(data, &["colors", mode, "primary_container"])?;
    let surfaces = backgrounds(background, opacity)?;
    let foreground = readable(on_surface, &surfaces, mode)?;
    let cursor = readable(primary, &surfaces, mode)?;
    let selection = primary_container.to_owned();
    let selection_fg = readable(&foreground, &[rgb(&selection)?.map(f64::from)], mode)?;
    let mut ansi = Vec::with_capacity(16);
    for index in 0..16 {
        let color = string_at(data, &["dank16", &format!("color{index}"), mode])?;
        ansi.push(Value::String(readable(color, &surfaces, mode)?));
    }
    Ok(serde_json::json!({
        "background": background,
        "foreground": foreground,
        "cursor": cursor,
        "selection": selection,
        "selection_fg": selection_fg,
        "ansi": ansi,
    }))
}

fn render(
    data: &Value,
    mode: &str,
    opacities: &[(String, f64)],
) -> Result<Vec<(String, String)>, String> {
    let opacity = |name: &str| {
        opacities
            .iter()
            .find(|(variant, _)| variant == name)
            .map(|(_, value)| *value)
            .ok_or_else(|| format!("Missing opacity for {name} mode"))
    };
    let palettes = [
        ("dark", palette(data, "dark", opacity("dark")?)?),
        ("light", palette(data, "light", opacity("light")?)?),
    ];
    let active = palettes
        .iter()
        .find(|(variant, _)| *variant == mode)
        .map(|(_, value)| value)
        .ok_or_else(|| format!("Unsupported mode {mode:?}; expected dark or light"))?;
    let background = active["background"].as_str().unwrap();
    let foreground = active["foreground"].as_str().unwrap();
    let cursor = active["cursor"].as_str().unwrap();
    let selection = active["selection"].as_str().unwrap();
    let selection_fg = active["selection_fg"].as_str().unwrap();
    let ansi: Vec<&str> = active["ansi"]
        .as_array()
        .unwrap()
        .iter()
        .map(|value| value.as_str().unwrap())
        .collect();

    let mut kitty = vec![
        format!("foreground {foreground}"),
        format!("background {background}"),
        format!("cursor {cursor}"),
        format!("cursor_text_color {background}"),
        format!("selection_background {selection}"),
        format!("selection_foreground {selection_fg}"),
    ];
    kitty.extend(
        ansi.iter()
            .enumerate()
            .map(|(index, color)| format!("color{index} {color}")),
    );

    let mut ghostty = vec![
        format!("foreground = {foreground}"),
        format!("background = {background}"),
        format!("cursor-color = {cursor}"),
        format!("cursor-text = {background}"),
        format!("selection-background = {selection}"),
        format!("selection-foreground = {selection_fg}"),
    ];
    ghostty.extend(
        ansi.iter()
            .enumerate()
            .map(|(index, color)| format!("palette = {index}={color}")),
    );

    let mut foot = Vec::new();
    for (variant, colors) in &palettes {
        let background = colors["background"].as_str().unwrap();
        let cursor = colors["cursor"].as_str().unwrap();
        foot.extend([
            format!("[colors-{variant}]"),
            format!(
                "foreground={}",
                colors["foreground"]
                    .as_str()
                    .unwrap()
                    .trim_start_matches('#')
            ),
            format!("background={}", background.trim_start_matches('#')),
            format!(
                "selection-foreground={}",
                colors["selection_fg"]
                    .as_str()
                    .unwrap()
                    .trim_start_matches('#')
            ),
            format!(
                "selection-background={}",
                colors["selection"]
                    .as_str()
                    .unwrap()
                    .trim_start_matches('#')
            ),
            format!(
                "cursor={} {}",
                background.trim_start_matches('#'),
                cursor.trim_start_matches('#')
            ),
        ]);
        for (index, color) in colors["ansi"].as_array().unwrap().iter().enumerate() {
            foot.push(format!(
                "{}{}={}",
                if index < 8 { "regular" } else { "bright" },
                index % 8,
                color.as_str().unwrap().trim_start_matches('#')
            ));
        }
    }

    Ok(vec![
        (
            "kitty/dotdots-contrast.conf".to_owned(),
            kitty.join("\n") + "\n",
        ),
        (
            "ghostty/dotdots-contrast".to_owned(),
            ghostty.join("\n") + "\n",
        ),
        ("foot/dotdots-colors.ini".to_owned(), foot.join("\n") + "\n"),
    ])
}

fn write_changed(path: &Path, content: &str) -> Result<bool, String> {
    match fs::symlink_metadata(path) {
        Ok(metadata) if metadata.file_type().is_symlink() => {
            return Err(format!(
                "Refusing to replace managed theme symlink: {}",
                path.display()
            ));
        }
        Ok(_)
            if fs::read_to_string(path)
                .map_err(|error| format!("Cannot read {}: {error}", path.display()))?
                == content =>
        {
            return Ok(false);
        }
        Ok(_) => {}
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => {}
        Err(error) => return Err(format!("Cannot inspect {}: {error}", path.display())),
    }
    let parent = path
        .parent()
        .ok_or_else(|| format!("No parent directory for {}", path.display()))?;
    fs::create_dir_all(parent)
        .map_err(|error| format!("Cannot create {}: {error}", parent.display()))?;
    let file_name = path
        .file_name()
        .and_then(|name| name.to_str())
        .unwrap_or("palette");
    let mut temporary = None;
    for _ in 0..100 {
        let sequence = TEMP_SEQUENCE.fetch_add(1, Ordering::Relaxed);
        let candidate = parent.join(format!(
            ".{file_name}.{}.{}.tmp",
            std::process::id(),
            sequence
        ));
        match OpenOptions::new()
            .write(true)
            .create_new(true)
            .mode(0o644)
            .open(&candidate)
        {
            Ok(mut file) => {
                if let Err(error) = file.write_all(content.as_bytes()) {
                    let _ = fs::remove_file(&candidate);
                    return Err(format!("Cannot write {}: {error}", candidate.display()));
                }
                file.set_permissions(fs::Permissions::from_mode(0o644))
                    .map_err(|error| {
                        format!("Cannot set permissions on {}: {error}", candidate.display())
                    })?;
                temporary = Some(candidate);
                break;
            }
            Err(error) if error.kind() == std::io::ErrorKind::AlreadyExists => continue,
            Err(error) => {
                return Err(format!(
                    "Cannot create temporary file in {}: {error}",
                    parent.display()
                ));
            }
        }
    }
    let temporary = temporary
        .ok_or_else(|| format!("Cannot allocate temporary file in {}", parent.display()))?;
    if let Err(error) = fs::rename(&temporary, path) {
        let _ = fs::remove_file(&temporary);
        return Err(format!("Cannot replace {}: {error}", path.display()));
    }
    Ok(true)
}

fn parse_args(
    args: impl Iterator<Item = String>,
) -> Result<(PathBuf, PathBuf, String, f64, f64), String> {
    let mut source = None;
    let mut config_home = None;
    let mut mode = None;
    let mut dark_opacity = None;
    let mut light_opacity = None;
    let mut args = args.peekable();
    while let Some(flag) = args.next() {
        let value = args
            .next()
            .ok_or_else(|| format!("Missing value for {flag}"))?;
        match flag.as_str() {
            "--source" => source = Some(PathBuf::from(value)),
            "--config-home" => config_home = Some(PathBuf::from(value)),
            "--mode" => mode = Some(value),
            "--dark-opacity" => {
                dark_opacity = Some(
                    value
                        .parse::<f64>()
                        .map_err(|error| format!("Invalid dark opacity: {error}"))?,
                )
            }
            "--light-opacity" => {
                light_opacity = Some(
                    value
                        .parse::<f64>()
                        .map_err(|error| format!("Invalid light opacity: {error}"))?,
                )
            }
            _ => return Err(format!("Unknown argument {flag}")),
        }
    }
    Ok((
        source.ok_or("Missing --source")?,
        config_home.ok_or("Missing --config-home")?,
        mode.ok_or("Missing --mode")?,
        dark_opacity.ok_or("Missing --dark-opacity")?,
        light_opacity.ok_or("Missing --light-opacity")?,
    ))
}

fn run() -> Result<(), String> {
    let (source, config_home, mode, dark_opacity, light_opacity) = parse_args(env::args().skip(1))?;
    if mode != "dark" && mode != "light" {
        return Err("Mode must be dark or light".to_owned());
    }
    let opacities = [
        ("dark".to_owned(), dark_opacity),
        ("light".to_owned(), light_opacity),
    ];
    if opacities
        .iter()
        .any(|(_, opacity)| !opacity.is_finite() || !(0.0..=1.0).contains(opacity))
    {
        return Err("Opacity must be between zero and one".to_owned());
    }
    if !source.exists() {
        return Ok(()); // DMS has not generated its first palette yet.
    }
    let text = fs::read_to_string(&source)
        .map_err(|error| format!("Cannot read {}: {error}", source.display()))?;
    let data: Value = serde_json::from_str(&text)
        .map_err(|error| format!("Cannot parse {}: {error}", source.display()))?;
    // Render and validate both modes before replacing any output.
    for (relative, content) in render(&data, &mode, &opacities)? {
        if write_changed(&config_home.join(&relative), &content)? {
            println!("{relative}");
        }
    }
    Ok(())
}

fn main() -> ExitCode {
    match run() {
        Ok(()) => ExitCode::SUCCESS,
        Err(error) => {
            eprintln!("{error}");
            ExitCode::FAILURE
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::time::{SystemTime, UNIX_EPOCH};

    fn sample_data() -> Value {
        let mut data = serde_json::json!({
            "colors": {},
            "dank16": {},
        });
        for (mode, background) in [("dark", "#111318"), ("light", "#f9f9ff")] {
            data["colors"][mode] = serde_json::json!({
                "background": background,
                "on_surface": "#888888",
                "primary": "#6687c4",
                "primary_container": background,
            });
            for index in 0..16 {
                data["dank16"][format!("color{index}")][mode] = Value::String("#778899".to_owned());
            }
        }
        data
    }

    fn temp_dir() -> PathBuf {
        let id = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_nanos();
        let path = env::temp_dir().join(format!("terminal-contrast-{}-{id}", std::process::id()));
        fs::create_dir_all(&path).unwrap();
        path
    }

    #[test]
    fn corrected_colors_meet_contrast_across_wallpaper_range_and_are_idempotent() {
        for (mode, background, opacity) in [("light", "#f9f9ff", 0.8), ("dark", "#111318", 0.75)] {
            let bounds = backgrounds(background, opacity).unwrap();
            for color in [
                "#f9f9ff", "#c5daff", "#babcbe", "#e0e2e5", "#111318", "#183a6a", "#888888",
            ] {
                let corrected = readable(color, &bounds, mode).unwrap();
                assert_eq!(readable(&corrected, &bounds, mode).unwrap(), corrected);
                let corrected_rgb = rgb(&corrected).unwrap().map(f64::from);
                for wallpaper in [0.0, 64.0, 128.0, 192.0, 255.0] {
                    let background_rgb = rgb(background).unwrap();
                    let surface = background_rgb
                        .map(|channel| opacity * f64::from(channel) + (1.0 - opacity) * wallpaper);
                    assert!(
                        contrast(corrected_rgb, surface) >= TARGET_CONTRAST,
                        "{mode} {corrected} on {surface:?}"
                    );
                }
            }
        }
    }

    #[test]
    fn already_readable_colors_are_preserved() {
        assert_eq!(
            readable("#494b51", &backgrounds("#f9f9ff", 0.8).unwrap(), "light").unwrap(),
            "#494b51"
        );
        assert_eq!(
            readable("#f8fbff", &backgrounds("#111318", 0.75).unwrap(), "dark").unwrap(),
            "#f8fbff"
        );
    }

    #[test]
    fn impossible_contrast_is_an_error() {
        let error = readable("#777777", &backgrounds("#111318", 0.0).unwrap(), "dark").unwrap_err();
        assert!(error.contains("Cannot achieve"));
    }

    #[test]
    fn renderers_share_all_sixteen_colors_in_each_format() {
        for mode in ["dark", "light"] {
            let outputs = render(
                &sample_data(),
                mode,
                &[("dark".to_owned(), 0.75), ("light".to_owned(), 0.8)],
            )
            .unwrap();
            assert_eq!(outputs.len(), 3);
            assert!(outputs[0].1.contains("color15 #"));
            assert!(outputs[1].1.contains("palette = 15=#"));
            assert!(outputs[2].1.contains("[colors-dark]"));
            assert!(outputs[2].1.contains("[colors-light]"));
            assert!(!outputs.iter().any(|(_, text)| text.contains("alpha=")));
        }
    }

    #[test]
    fn file_writes_are_atomic_idempotent_and_refuse_symlinks() {
        let directory = temp_dir();
        let target = directory.join("palette");
        assert!(write_changed(&target, "colors\n").unwrap());
        let modified = fs::metadata(&target).unwrap().modified().unwrap();
        assert!(!write_changed(&target, "colors\n").unwrap());
        assert_eq!(fs::metadata(&target).unwrap().modified().unwrap(), modified);
        let link = directory.join("link");
        std::os::unix::fs::symlink(&target, &link).unwrap();
        assert!(
            write_changed(&link, "replacement\n")
                .unwrap_err()
                .contains("symlink")
        );
        assert_eq!(fs::read_to_string(target).unwrap(), "colors\n");
        fs::remove_dir_all(directory).unwrap();
    }
}
