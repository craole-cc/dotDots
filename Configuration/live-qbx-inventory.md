# Live QBX Configuration Inventory

## Scope

This is a non-secret inventory of the live QBX user environment observed on 2026-08-08. It records configuration families, their likely declarative ownership, and gaps to resolve before a rebuild is considered preservation-safe.

The live system is currently running generation `nixos-system-QBX-26.05.20260418.b12141`. No activation or configuration change was performed during this inventory.

## Interpretation Rules

- A directory under `~/.config` is evidence that an application has been used or configured; it is not automatically a desired declarative module.
- Browser profiles, IDE state, databases, cookies, credentials, caches, locks, generated theme files, and runtime snapshots must not be copied into Nix modules wholesale.
- A setting becomes rebuild-owned only when its source is represented by a repository module, API/user policy, or an explicit source file under `Configuration/`.
- Generated settings must be compared with their owning module's output rather than treated as independent source configuration.

## Live Desktop And Session Surface

| Live evidence | Observed setting or behavior | Repository owner/status |
|---|---|---|
| `.config/hypr/dms/*` | DMS-generated Hyprland binds, gaps 8, outer gaps 8, border 2, rounding 12, two-monitor outputs | `Modules/nix/home/interface/manager/hyprland/*` and DMS integration; generated DMS files need comparison against module output |
| `.config/DankMaterialShell/settings.json` | Dynamic theme, Matugen tonal-spot, HDMI-A-2 target, 12px radius, 24-hour clock, widget/control-center visibility and ordering | DMS provider module is selected, but these user settings are not yet represented as a repository-owned DMS settings module |
| `.config/niri/config.kdl` | Niri configuration exists, including numlock, touchpad tap/natural-scroll, layout gaps 16, column presets and bindings | `Modules/nix/home/interface/manager/niri/*`; likely dormant while Hyprland is live, but must be classified rather than deleted |
| `.config/foot/*` | Foot server, `foot` app-id, DMS colors, repository wrapper behavior | `Modules/nix/home/terminal/foot/*`, `API/nix/users/craole/programs/foot/*`; preserve wrappers and theme source |
| `.config/fuzzel/*` | Overlay launcher and `$TERMINAL` integration | `Modules/nix/home/interface/components/fuzzel/*`; verify generated config retains the wrapper and theme |
| `.config/vicinae/*` | Server configuration, 0.95 opacity, close-on-focus-loss, search files, launcher behavior | `Modules/nix/home/interface/components/vicinae/*`; verify `vicinae toggle` binding and settings |
| `.config/systemd/user/*` | DMS, Foot, Vicinae, Hypridle, Hyprpaper, Hyprsunset, Hyprpolkitagent, PipeWire, portals, Wayland session targets | Home Manager modules plus NixOS session modules; must compare enabled units and `ExecStart`/conditions |
| `waybar.service` | User unit exists from the live system profile | Panel selection and generated service must be checked against canonical panel choice; do not assume Waybar is unused merely because DMS is selected |
| `.config/environment.d/*` and user environment | `BROWSER`, `EDITOR`, `TERMINAL`, `LAUNCHER`, theme/wallpaper variables, Wayland/Qt/GTK variables | `Modules/nix/core/environment/*`, `Modules/nix/home/environment/*`, API user policy; requires name/value diff |

## Application Configuration Families

| Family | Live evidence | Declarative owner or gap |
|---|---|---|
| Browsers | `.config/zen`, `.config/chromium`, `.config/google-chrome`, `.config/epiphany`, `.config/FreeTube` | Zen is owned by `Modules/nix/home/browser/zen/*`; Chromium/Chrome/other profiles contain state and must be classified separately |
| Editors and IDEs | `.config/helix`, `Code`, `Code - Insiders`, `VSCodium`, `Antigravity`, `JetBrains`, `zed`, `.config/vscode-*` | Helix, VS Code, Office, and Zed have repository modules; IDE extensions/settings need explicit comparison, not profile copying |
| Terminals | `.config/foot`, `ghostty`, `kitty`, `wezterm`, `warp-terminal`, `.config/alacritty` | Foot and Ghostty have modules; other terminal settings are not proven owned by the active profile |
| Shells and CLI | `.config/nushell`, `tmux`, `direnv`, `ripgrep`, `ripgrep-all`, `fd`, `bat`, `btop`, `git`, `jj`, `topgrade.d`, `macchina`, `gitfetch`, `gitui` | Several have modules or shared `Configuration/*` sources; catalog exact files and values before claiming parity |
| Media | `.config/mpv`, `obs-studio`, `mpd`, `vlc`, `FreeTube`, `qBittorrent`, `darktable`, `nomacs`, `qimgv`, `onlyoffice` | MPV, OBS, editing, and Office have modules; qBittorrent/VLC/nomacs/qimgv settings currently need explicit owners |
| File managers | `.config/yazi`, `doublecmd`, `nautilus`, `Thunar`, KDE file-manager settings | Yazi and some integration behavior have modules; Double Commander and GUI file-manager preferences need coverage decisions |
| Desktop shell and themes | `DankMaterialShell`, `caelestia`, `noctalia`, `cosmic`, GTK/Qt theme files, `tinted-theming`, `darkman` | Multiple historical/alternative shells coexist in the home directory; active selection and generated theme ownership must be determined from live units and API policy |
| Communications | Telegram Desktop, Vesktop, Vencord, Equicord, Legcord, Evolution, Equibop | Mostly application state and credentials; preserve packages and selected declarative preferences without importing profiles |
| Graphics and productivity | Ansel, Inkscape, Darktable, Double Commander, OnlyOffice, Nomacs, qimgv | Package presence is partly covered by media/editing modules; per-application settings need explicit ownership or deliberate state classification |
| Audio/Bluetooth | PipeWire, WirePlumber, Pulse, Cava, Blueman, BlueZ, `51-dms-audio-aliases.conf` | Core audio/Bluetooth and Cava modules exist; compare DMS aliases and generated WirePlumber files |
| KDE/Plasma residue | Top-level KDE configuration files, `kwinrc`, `kglobalshortcutsrc`, `kwinoutputconfig.json`, Dolphin/KDE app settings | Live session is Hyprland; classify as historical/portable application state unless an active service or policy consumes it |

## Active User Services

The live user session has enabled or generated units for:

- `dms.service`
- `foot.service` and `foot-server.service`
- `vicinae.service`
- `hypridle.service`
- `hyprpaper.service`
- `hyprpolkitagent.service`
- `hyprsunset.service`
- `darkman.service`
- `nh-clean.timer`
- PipeWire, WirePlumber, portals, speech dispatcher, Bluetooth/OBEX, GPG agent
- Wayland session and Hyprland session targets
- `waybar.service` exists in the live system profile and requires explicit classification

The live system also reports the known failed services `nscd.service` and `systemd-suspend.service`; these are unrelated and must remain untouched.

## Concrete Settings That Need Module Representation

The following are not just package-presence questions and need explicit module ownership or a deliberate preservation decision:

1. DMS settings JSON: theme mode, Matugen scheme/monitor, radius, clock, widgets, system indicators, and feature visibility.
2. Hyprland DMS generated settings: gaps, border, rounding, monitor layout, binds, and DMS include order.
3. Hyprland user settings outside DMS: startup, rules, workspace assignments, portals, idle/paper/sunset/polkit services.
4. Foot: server behavior, app-id, color source, and the repository's `feet` wrapper.
5. Fuzzel: overlay layer, terminal variable, launcher wrapper and theme.
6. Vicinae: server service, settings, opacity, and `vicinae toggle` binding.
7. Environment names and values: especially `BROWSER`, `EDITOR`, `TERMINAL`, `LAUNCHER`, theme/wallpaper variables, and Qt/GTK/Wayland integration.
8. Yazi: mtime linemode, column ratio, natural sorting, previewers, openers, and editor/media associations.
9. MPV: the live file delegates to `$DOTS/Configuration/mpv/config`; that source must be compared directly.
10. Media/download applications: qBittorrent paths, tracker policy, port settings, OBS profile/plugin settings, and media-editor associations. Secrets and credentials must not be copied.

## Current Readiness Assessment

The repository currently has broad module coverage, but the inventory exposes a parity gap. `nix flake check` and QBX dry-build prove evaluation, not preservation of this live surface. Before activation readiness, the candidate must be forced and compared for:

- package/application presence;
- enabled system and user units;
- environment variables;
- generated config files;
- desktop/session settings;
- user application settings with secrets/state excluded;
- package provenance and version changes.

The next repair work should be driven by this inventory, not by DMS or Zen alone.
