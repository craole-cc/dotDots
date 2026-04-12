{lib, ...}: let
  inherit (lib.attrsets) attrByPath recursiveUpdate;
  inherit (lib.strings) hasInfix toLower;

  __exports = {
    internal = {inherit defaults uiDefaults mkApplications;};
    external = {mkSchemaApplications = mkApplications;};
  };

  # ── Defaults ────────────────────────────────────────────────────────────────

  defaults = {
    browser = {
      primary = "zen-twilight";
      secondary = "chromium";
    };
    terminal = {
      primary = "ghostty";
      secondary = "foot";
    };
    editor = {
      tty = {
        primary = "helix";
        secondary = "neovim";
      };
      gui = {
        primary = "vscode";
        secondary = "zed";
      };
    };
    launcher = {
      primary = "vicinae";
      secondary = "fuzzel";
    };
    explorer = {
      primary = "yazi";
      secondary = "nautilus";
    };
    bar = null;
    prompt = "starship";
    allowed = [];
  };

  uiDefaults = {
    launcher = {
      pri = "vicinae";
      sec = "vicinae";
    };
    terminal = {
      pri = "kitty";
      sec = "ghostty";
    };
    explorer = {
      pri = "doublecmd";
      sec = "yazi";
    };
    browser = {
      pri = "zen-twilight";
      sec = "chromium";
    };
    editor = {
      pri = "vscode";
      sec = "helix";
    };
  };

  # ── Command resolution ───────────────────────────────────────────────────────
  # Maps app names to the actual binary command to run

  commandMap = {
    browser = {
      "zen-twilight" = "zen";
      "zen-beta" = "zen";
      "zen" = "zen";
      "chromium" = "chromium";
      "firefox" = "firefox";
      "brave" = "brave";
      "vivaldi" = "vivaldi";
      "floorp" = "floorp";
      "microsoft-edge" = "microsoft-edge";
      "google-chrome" = "google-chrome-stable";
    };
    terminal = {
      "foot" = "feet";
      "ghostty" = "ghostty";
      "kitty" = "kitty";
      "alacritty" = "alacritty";
      "wezterm" = "wezterm";
      "warp-terminal" = "warp-terminal";
      "rio" = "rio";
    };
    editor = {
      "helix" = "hx";
      "neovim" = "nvim";
      "nvim" = "nvim";
      "vscode" = "code";
      "vscodium" = "codium";
      "zed" = "zeditor";
      "zeditor" = "zeditor";
      "vim" = "vim";
      "nano" = "nano";
      "emacs" = "emacs";
      "sublime" = "subl";
    };
    launcher = {
      "vicinae" = "vicinae toggle";
      "fuzzel" = "pkill fuzzel || fuzzel --list-executables-in-path";
      "wofi" = "wofi";
      "rofi" = "rofi";
      "tofi" = "tofi";
      "dmenu" = "dmenu";
      "ulauncher" = "ulauncher";
    };
    explorer = {
      "yazi" = "yazi";
      "nautilus" = "org.gnome.Nautilus";
      "dolphin" = "dolphin";
      "thunar" = "thunar";
      "nemo" = "nemo";
    };
    bar = {
      "waybar" = "waybar";
      "caelestia" = "caelestia";
      "noctalia" = "noctalia";
      "ags" = "ags";
      "eww" = "eww";
      "yambar" = "yambar";
    };
  };

  # ── Class resolution ─────────────────────────────────────────────────────────
  # Maps commands to their window class for use in window rules

  classMap = {
    "zen" = "zen";
    "chromium" = "chromium";
    "firefox" = "firefox";
    "brave" = "brave";
    "vivaldi" = "vivaldi";
    "floorp" = "floorp";
    "microsoft-edge" = "microsoft-edge";
    "google-chrome-stable" = "google-chrome";
    "feet" = "foot";
    "ghostty" = "com.mitchellh.ghostty";
    "kitty" = "kitty";
    "alacritty" = "Alacritty";
    "wezterm" = "org.wezfurlong.wezterm";
    "warp-terminal" = "dev.warp.Warp";
    "hx" = "Helix";
    "nvim" = "nvim";
    "code" = "code";
    "codium" = "VSCodium";
    "zeditor" = "dev.zed.Zed";
    "vim" = "vim";
    "vicinae" = "vicinae";
    "fuzzel" = "fuzzel";
    "wofi" = "wofi";
    "rofi" = "rofi";
    "yazi" = "yazi";
    "org.gnome.Nautilus" = "org.gnome.Nautilus";
    "dolphin" = "dolphin";
    "thunar" = "thunar";
  };

  getCommand = category: name: let
    n = toLower name;
  in
    attrByPath [category n] n commandMap;

  getClass = command: let
    n = toLower command;
  in
    if hasInfix "fuzzel" n
    then "fuzzel"
    else if hasInfix "vicinae" n
    then "vicinae"
    else if hasInfix "yazi" n
    then "yazi"
    else if hasInfix "ghostty" n
    then "com.mitchellh.ghostty"
    else if hasInfix "zeditor" n
    then "dev.zed.Zed"
    else if hasInfix "nautilus" n
    then "org.gnome.Nautilus"
    else classMap.${n} or n;

  mkEntry = category: name: let
    command = getCommand category name;
  in {
    inherit command name;
    class = getClass command;
  };

  # ── Resolution ───────────────────────────────────────────────────────────────

  mkApplications = {
    host,
    user ? {},
  }: let
    raw =
      recursiveUpdate
      (recursiveUpdate defaults (host.applications or {}))
      (user.applications or {});
  in {
    browser = {
      primary = mkEntry "browser" raw.browser.primary;
      secondary = mkEntry "browser" raw.browser.secondary;
    };
    terminal = {
      primary = mkEntry "terminal" raw.terminal.primary;
      secondary = mkEntry "terminal" raw.terminal.secondary;
    };
    editor = {
      tty = {
        primary = mkEntry "editor" raw.editor.tty.primary;
        secondary = mkEntry "editor" raw.editor.tty.secondary;
      };
      gui = {
        primary = mkEntry "editor" raw.editor.gui.primary;
        secondary = mkEntry "editor" raw.editor.gui.secondary;
      };
      primary = mkEntry "editor" raw.editor.gui.primary;
      secondary = mkEntry "editor" raw.editor.gui.secondary;
    };
    launcher = {
      primary = mkEntry "launcher" raw.launcher.primary;
      secondary = mkEntry "launcher" raw.launcher.secondary;
    };
    explorer = {
      primary = mkEntry "explorer" raw.explorer.primary;
      secondary = mkEntry "explorer" raw.explorer.secondary;
    };
    bar = {
      primary = mkEntry "bar" (raw.bar or "waybar");
    };
    inherit raw;
    inherit (raw) prompt allowed;
  };
in
  __exports.internal // {__rootAliases = __exports.external;}
