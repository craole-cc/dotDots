# schema/applications.nix
{
  _,
  lib,
  ...
}: let
  inherit (_.applications.resolution) browsers terminals launchers editors bars;
  inherit (lib.attrsets) recursiveUpdate;
  inherit (lib.strings) hasInfix toLower;

  __exports = {
    internal = {inherit defaults mkApplications;};
    external = {mkSchemaApplications = mkApplications;};
  };

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
  };

  # Class resolution — UI concern, stays here
  classMap = {
    "feet" = "foot";
    "ghostty" = "com.mitchellh.ghostty";
    "zeditor" = "dev.zed.Zed";
    "fuzzel" = "fuzzel";
    "vicinae" = "vicinae";
    "zen" = "zen";
    "zen-twilight" = "zen";
    "chromium" = "chromium";
    "code" = "code";
    "yazi" = "yazi";
    "org.gnome.nautilus" = "org.gnome.Nautilus";
  };

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
    else classMap.${n} or n;

  mkEntry = command: {
    inherit command;
    class = getClass command;
  };

  mkApplications = {
    host,
    user ? {},
    pkgs,
    inputs ? {},
    system ? pkgs.stdenv.hostPlatform.system,
  }: let
    # Merge raw config — user overrides host overrides defaults
    raw =
      recursiveUpdate
      (defaults // (host.applications or {}))
      (user.applications or {});

    # Resolve commands via resolution.nix (single source of truth)
    browserCmds = browsers.commands {
      inherit pkgs inputs system;
      appConfig = raw.browser;
    };
    terminalCmds = terminals.commands {
      inherit pkgs inputs system;
      appConfig = raw.terminal;
    };
    launcherCmds = launchers.commands {
      inherit pkgs inputs system;
      appConfig = raw.launcher;
    };
    editorCmds = editors.commands {
      inherit pkgs inputs system;
      editorConfig = raw.editor;
    };
    barCmds = bars.commands {
      inherit pkgs inputs system;
      appConfig =
        if raw.bar != null
        then {primary = raw.bar;}
        else {};
    };

    # Explorer has no resolution.nix entry yet — resolve directly
    explorerPrimary = raw.explorer.primary or defaults.explorer.primary;
    explorerSecondary = raw.explorer.secondary or defaults.explorer.secondary;
  in {
    browser = {
      primary = mkEntry browserCmds.primary;
      secondary = mkEntry (browserCmds.secondary or explorerSecondary);
    };
    terminal = {
      primary = mkEntry terminalCmds.primary;
      secondary = mkEntry terminalCmds.secondary;
    };
    launcher = {
      primary = mkEntry launcherCmds.primary;
      secondary = mkEntry launcherCmds.secondary;
    };
    editor = {
      primary = mkEntry editorCmds.editor;
      secondary = mkEntry editorCmds.visual;
    };
    explorer = {
      primary = mkEntry explorerPrimary;
      secondary = mkEntry explorerSecondary;
    };
    bar = {
      primary = mkEntry (barCmds.primary or "waybar");
    };
    prompt = raw.prompt or defaults.prompt;
    allowed = raw.allowed or [];

    # Raw config preserved for downstream consumers that need original names
    raw = raw;
  };
in
  __exports.internal // {_rootAliases = __exports.external;}
