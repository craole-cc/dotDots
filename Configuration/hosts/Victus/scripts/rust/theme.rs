#!/usr/bin/env rust-script
//! ```cargo
//! [dependencies]
//! serde_json = "1.0"
//! miette = { version = "7.0", features = ["fancy"] }
//! ```

use miette::{Context, IntoDiagnostic, Result};
use serde_json::Value;
use std::{
    collections::HashMap,
    env, fs,
    path::{Path, PathBuf},
    process::Command,
};

#[derive(Debug)]
enum Variant {
    Light,
    Dark,
}

impl Variant {
    fn as_str(&self) -> &str {
        match self {
            Self::Light => "light",
            Self::Dark => "dark",
        }
    }
}

#[derive(Debug)]
struct AppTheme {
    light: &'static str,
    dark: &'static str,
}

impl AppTheme {
    const fn new(light: &'static str, dark: &'static str) -> Self {
        Self { light, dark }
    }

    fn get(&self, variant: &Variant) -> &str {
        match variant {
            Variant::Light => self.light,
            Variant::Dark => self.dark,
        }
    }
}

struct ThemeConfig {
    variant: Variant,
    apps: HashMap<&'static str, AppTheme>,
}

impl ThemeConfig {
    fn new(current_theme: &str) -> Self {
        let variant = if current_theme.contains("light") {
            Variant::Light
        } else {
            Variant::Dark
        };

        let mut apps = HashMap::new();
        apps.insert(
            "helix",
            AppTheme::new("seoul256-light-hard", "seoul256-dark-soft"),
        );
        apps.insert(
            "ghostty",
            AppTheme::new("Catppuccin Latte", "Catppuccin Frappe"),
        );
        apps.insert(
            "bat",
            AppTheme::new("Catppuccin-latte", "Catppuccin-frappe"),
        );
        apps.insert(
            "vscode",
            AppTheme::new("Bluloco Light Italic", "Bluloco Dark Italic"),
        );
        apps.insert(
            "zed",
            AppTheme::new("Catppuccin Latte", "Catppuccin Frappé"),
        );

        Self { variant, apps }
    }

    fn get_theme(&self, app: &str) -> Option<&str> {
        self.apps.get(app).map(|theme| theme.get(&self.variant))
    }
}

trait ThemeUpdater {
    fn name(&self) -> &'static str;
    fn update(&self, theme: &str, home: &Path) -> Result<()>;
}

struct HelixUpdater;
impl ThemeUpdater for HelixUpdater {
    fn name(&self) -> &'static str {
        "helix"
    }

    fn update(&self, theme: &str, home: &Path) -> Result<()> {
        let config_dir = home.join(".config/helix");
        fs::create_dir_all(&config_dir)
            .into_diagnostic()
            .wrap_err("Failed to create Helix config directory")?;

        let content = format!("theme = \"{}\"\n", theme);
        fs::write(config_dir.join("theme-override.toml"), content)
            .into_diagnostic()
            .wrap_err("Failed to write Helix theme config")?;

        Ok(())
    }
}

struct ZedUpdater;
impl ThemeUpdater for ZedUpdater {
    fn name(&self) -> &'static str {
        "zed"
    }

    fn update(&self, _theme: &str, home: &Path) -> Result<()> {
        let config_path = home.join(".config/zed/settings.json");

        if !config_path.exists() {
            return Ok(());
        }

        let content = fs::read_to_string(&config_path)
            .into_diagnostic()
            .wrap_err("Failed to read Zed config")?;

        let mut settings: Value = serde_json::from_str(&content)
            .into_diagnostic()
            .wrap_err("Failed to parse Zed config JSON")?;

        if let Some(theme) = settings.get_mut("theme") {
            theme["mode"] = Value::String("system".to_string());
        }

        fs::write(
            &config_path,
            serde_json::to_string_pretty(&settings).into_diagnostic()?,
        )
        .into_diagnostic()
        .wrap_err("Failed to write Zed config")?;

        Ok(())
    }
}

struct GhosttyUpdater;
impl ThemeUpdater for GhosttyUpdater {
    fn name(&self) -> &'static str {
        "ghostty"
    }

    fn update(&self, theme: &str, home: &Path) -> Result<()> {
        let config_dir = home.join(".config/ghostty");
        fs::create_dir_all(&config_dir)
            .into_diagnostic()
            .wrap_err("Failed to create Ghostty config directory")?;

        let content = format!("theme = {}\n", theme);
        fs::write(config_dir.join("config"), content)
            .into_diagnostic()
            .wrap_err("Failed to write Ghostty config")?;

        Ok(())
    }
}

fn get_updaters() -> Vec<Box<dyn ThemeUpdater>> {
    vec![
        Box::new(HelixUpdater),
        Box::new(ZedUpdater),
        Box::new(GhosttyUpdater),
    ]
}

fn run_command(program: &str, args: &[&str]) -> Result<()> {
    Command::new(program)
        .args(args)
        .output()
        .into_diagnostic()
        .wrap_err_with(|| format!("Failed to run {}", program))?;
    Ok(())
}

fn update_gnome(variant: &Variant) -> Result<()> {
    run_command(
        "gsettings",
        &[
            "set",
            "org.gnome.desktop.interface",
            "color-scheme",
            &format!("prefer-{}", variant.as_str()),
        ],
    )
}

fn send_notification(variant: &Variant) -> Result<()> {
    run_command(
        "notify-send",
        &["Theme Sync", &format!("Applied {} theme", variant.as_str())],
    )
}

fn is_enabled(env_var: &str) -> bool {
    env::var(env_var).unwrap_or_default() == "1"
}

fn get_current_theme() -> Result<String> {
    let output = Command::new("tinty")
        .arg("current")
        .output()
        .into_diagnostic()
        .wrap_err("Failed to run tinty")?;

    Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
}

fn main() -> Result<()> {
    let current = get_current_theme()?;
    let config = ThemeConfig::new(&current);
    let home = PathBuf::from(
        env::var("HOME")
            .into_diagnostic()
            .wrap_err("HOME environment variable not set")?,
    );

    let updaters = get_updaters();

    // Update each enabled application
    for updater in updaters {
        let app_name = updater.name();
        let env_var = format!("{}_ENABLED", app_name.to_uppercase());

        if is_enabled(&env_var) {
            if let Some(theme) = config.get_theme(app_name) {
                updater
                    .update(theme, &home)
                    .wrap_err_with(|| format!("Failed to update {}", app_name))?;
            }
        }
    }

    // Update system theme and notify
    update_gnome(&config.variant).ok();
    send_notification(&config.variant).ok();

    Ok(())
}
