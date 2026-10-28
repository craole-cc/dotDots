# Every source is declared once, tagged with the group it belongs to.
# `group` is ours (stripped before pkgsFrom sees it); the other keys
# (discover, exe, input) are passed through unchanged.
let
  s = group: extra: {inherit group;} // extra;
in {
  alejandra = s "formatters" {}; #? opinionated Nix formatter
  bash = s "shells" {}; #? Bourne-again shell
  bat = s "files" {}; #? cat with syntax highlighting
  biome = s "formatters" {}; #? fast formatter + linter (JS/TS/JSON/CSS)
  coreutils = s "core" {discover = true;}; #? core file, text and shell utilities
  curl = s "networking" {}; #? transfer data with URLs
  dash = s "shells" {}; #? lightweight POSIX sh (for `write.posix` shebangs)
  dbus = s "desktop-cli" {
    discover = true; #? dbus-send, dbus-monitor, ...
    exe = "dbus-send";
  };
  diffutils = s "core" {
    discover = true; #? cmp, diff, diff3, sdiff
    exe = "cmp";
  };
  dms-shell = s "desktop-ui" {input = "dank-material-shell";}; #? Dank Material Shell
  dprint = s "formatters" {}; #? pluggable multi-language code formatter
  dust = s "files" {}; #? intuitive du (disk usage)
  eza = s "files" {}; #? modern ls replacement
  fd = s "files" {}; #? simple, fast find alternative
  file = s "core" {}; #? determine file type
  findutils = s "core" {discover = true;}; #? xargs (find is covered by fd)
  fzf = s "files" {}; #? command-line fuzzy finder
  gawk = s "core" {discover = true;}; #? GNU awk
  gh = s "shells" {}; #? GitHub CLI
  git = s "shells" {}; #? distributed version control
  glib = s "desktop-cli" {
    discover = true; #? gdbus, gio, gsettings, ...
    exe = "gsettings";
  };
  gnugrep = s "core" {discover = true;}; #? GNU grep
  gnupatch = s "core" {exe = "patch";}; #? apply diff patches
  gnused = s "core" {discover = true;}; #? GNU sed
  gum = s "shells" {}; #? glamorous shell script helpers
  hyprpaper = s "desktop-ui" {}; #? wallpaper daemon for Hyprland
  iproute2 = s "networking" {
    discover = true; #? ip, ss, bridge, ...
    exe = "ip";
  };
  jaq = s "text" {}; #? jq-compatible JSON processor (Rust)
  jq = s "text" {}; #? command-line JSON processor
  libnotify = s "desktop-cli" {exe = "notify-send";}; #? desktop notifications
  moreutils = s "core" {discover = true;}; #? additional Unix tools (sponge, parallel, ...)
  ouch = s "archives" {}; #? unified (de)compressor (tar, zip, 7z, gz, xz, zst, ...)
  procps = s "system" {
    discover = true; #? pkill, pgrep, ps, top, ...
    exe = "pkill";
  };
  quickshell = s "desktop-ui" {input = "quickshell";}; #? QtQuick-based desktop shell
  ripgrep = s "text" {}; #? fast recursive grep (rg)
  sd = s "text" {}; #? intuitive sed alternative
  swaybg = s "desktop-ui" {}; #? wallpaper utility for Sway
  systemd = s "system" {
    discover = true; #? systemctl, journalctl, ...
    exe = "systemctl";
  };
  tree = s "core" {}; #? list directory contents as a tree
  util-linux = s "system" {
    discover = true; #? mount, lsblk, flock, logger, ...
    exe = "mount";
  };
  variety = s "desktop-ui" {}; #? wallpaper changer with scheduling & effects
  vscode-fhs = s "editors" {}; #? VS Code (FHS environment)
  vscode-insiders = s "editors" {
    input = "vscode-insiders";
    exe = "code-insiders";
  }; #? VS Code Insiders
  wl-clipboard = s "desktop-cli" {
    discover = true; #? wl-copy, wl-paste
    exe = "wl-copy";
  };
  xdg-utils = s "desktop-cli" {
    discover = true; #? xdg-open, xdg-mime, ...
    exe = "xdg-open";
  };
  yq-go = s "text" {}; #? portable YAML/JSON/XML processor (Go)
}
