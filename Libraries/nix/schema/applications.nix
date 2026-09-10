{
  _,
  lib,
  ...
}: let
  inherit (_.applications.registry) resolve;
  inherit (lib.attrsets) attrByPath recursiveUpdate;
  inherit (lib.strings) hasInfix toLower;

  __exports = {
    internal = {inherit defaults uiDefaults mkApplications;};
    external = {
      mkSchemaApplications = mkApplications;
    };
  };

  # ── Defaults ────────────────────────────────────────────────────────────────

  defaults = {
    browser = {
      primary = "zen-twilight";
      secondary = "chromium";
    };
    terminal = {
      # Kitty is the protocol-neutral schema default. Users/hosts may provide
      # protocol-specific overrides such as `terminal.wayland.primary = "foot"`.
      primary = "kitty";
      secondary = "ghostty";
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

  legacyCommand = category: name: let
    n = toLower name;
  in
    attrByPath [category n] n commandMap;

  legacyClass = command: let
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

  getCommand = category: name:
    if category == "browser"
    then
      (resolve {
        value = name;
        inherit category;
      }).exec
    else legacyCommand category name;

  getClass = category: name: let
    command = getCommand category name;
  in
    if category == "browser"
    then
      (
        (resolve {
          value = name;
          inherit category;
        }).names.class or command
      )
    else legacyClass command;

  mkEntry = category: name: {
    inherit name;
    command = getCommand category name;
    class = getClass category name;
  };

  # ── Resolution ───────────────────────────────────────────────────────────────

  mkApplications = {
    host,
    user ? {},
  }: let
    merged = recursiveUpdate (recursiveUpdate defaults (host.applications or {})) (
      user.applications or {}
    );

    userProtocol = (user.interface or {}).displayProtocol or null;
    hostProtocol = (host.interface or {}).displayProtocol or null;
    protocol =
      if userProtocol != null
      then userProtocol
      else hostProtocol;

    # App contracts may refine a category by display protocol. The selected
    # protocol override is folded into the normalized category and the
    # conditional branches are then removed from the consumer-facing contract.
    resolveProtocol = value: let
      override =
        if protocol != null
        then value.${protocol} or {}
        else {};
    in
      removeAttrs (recursiveUpdate value override) [
        "wayland"
        "x11"
        "xorg"
      ];

    raw = merged // {
      browser = resolveProtocol merged.browser;
      terminal = resolveProtocol merged.terminal;
      editor = resolveProtocol merged.editor;
      launcher = resolveProtocol merged.launcher;
      explorer = resolveProtocol merged.explorer;
    };
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
      primary = mkEntry "bar" (
        if raw.bar == null
        then "waybar"
        else raw.bar
      );
    };
    inherit raw;
    inherit (raw) prompt allowed;
  };
in
  __exports.internal // {__rootAliases = __exports.external;}
