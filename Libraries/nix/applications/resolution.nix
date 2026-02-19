{lib, ...}: let
  inherit (lib.attrsets) attrByPath hasAttrByPath;
  inherit (lib.lists) filter unique;

  /**
  mkApp - Create a generic application handler with flake support

  # Arguments
  - appMap: Attribute set mapping app names to functions that return {cmd, pkg, inputPath}
  - defaultApp: Default app name if none specified

  # Returns
  An attrset with {info, packages, commands} functions
  */
  mkApp = {
    appMap,
    defaultApp ? null,
  }: let
    info = {
      pkgs,
      inputs ? {},
      system ? "x86_64-linux",
      name,
    }: let
      appInfo = appMap.${name} or null;
    in
      if appInfo != null
      then
        if builtins.isFunction appInfo
        then appInfo {inherit pkgs inputs system;}
        else appInfo
      else {
        cmd = name;
        pkg = null;
        inputPath = null;
      };

    packages = {
      pkgs,
      inputs ? {},
      system ? "x86_64-linux",
      appConfig ? {},
    }: let
      primary = attrByPath ["primary"] defaultApp appConfig;
      secondary = attrByPath ["secondary"] null appConfig;

      # Normalize user input first
      normalizedPrimary =
        if primary != null
        then detectBrowserVariant primary
        else null;
      normalizedSecondary =
        if secondary != null
        then detectBrowserVariant secondary
        else null;

      getInfo = name:
        if name != null
        then info {inherit pkgs inputs system name;}
        else null;

      allInfos = filter (i: i != null) [
        (getInfo normalizedPrimary)
        (getInfo normalizedSecondary)
      ];

      # Try input path first (from specialArgs), then pkg
      getPkg = i:
        if i.inputPath != null
        then
          if hasAttrByPath i.inputPath inputs
          then attrByPath i.inputPath null inputs
          else i.pkg
        else i.pkg;

      allPkgs = map getPkg allInfos;
    in
      unique (filter (p: p != null) allPkgs);

    commands = {
      pkgs,
      inputs ? {},
      system ? "x86_64-linux",
      appConfig ? {},
    }: let
      primary = attrByPath ["primary"] defaultApp appConfig;
      secondary = attrByPath ["secondary"] null appConfig;

      # Normalize user input first
      normalizedPrimary =
        if primary != null
        then detectBrowserVariant primary
        else null;
      normalizedSecondary =
        if secondary != null
        then detectBrowserVariant secondary
        else null;

      primaryInfo =
        if normalizedPrimary != null
        then
          info {
            inherit pkgs inputs system;
            name = normalizedPrimary;
          }
        else null;

      secondaryInfo =
        if normalizedSecondary != null
        then
          info {
            inherit pkgs inputs system;
            name = normalizedSecondary;
          }
        else null;
    in {
      primary =
        if primaryInfo != null
        then primaryInfo.cmd
        else null;
      secondary =
        if secondaryInfo != null
        then secondaryInfo.cmd
        else null;
    };
  in {
    inherit info packages commands;
  };

  # Helper to detect browser variant (similar to detectFirefoxVariant)
  # TODO: move to parse.nix
  detectBrowserVariant = input: let
    lowerInput = lib.toLower input;
  in
    # Zen Browser variants
    if lib.hasInfix "zen" lowerInput && (lib.hasInfix "beta" lowerInput || lib.hasInfix "nightly" lowerInput)
    then "zen-beta"
    else if lib.hasInfix "zen" lowerInput
    then "zen-twilight"
    # Edge/Chromium variants
    else if lib.hasInfix "edge" lowerInput
    then "edge"
    else if lib.hasInfix "chrome" lowerInput && lib.hasInfix "google" lowerInput
    then "chrome"
    else if lib.hasInfix "chromium" lowerInput
    then "chromium"
    # Other browsers
    else if lib.hasInfix "brave" lowerInput
    then "brave"
    else if lib.hasInfix "vivaldi" lowerInput
    then "vivaldi"
    else if lib.hasInfix "floorp" lowerInput
    then "floorp"
    else if lib.hasInfix "firefox" lowerInput
    then "firefox"
    # Default to input if no match
    else input;

  # Application Maps
  browsers = mkApp {
    defaultApp = "firefox";
    appMap = {
      firefox = {pkgs, ...}: {
        cmd = "firefox";
        pkg = pkgs.firefox;
        inputPath = null;
      };

      "zen-twilight" = {
        pkgs,
        system,
        ...
      }: {
        cmd = "zen-twilight";
        pkg = pkgs.zen-browser or null;
        inputPath = ["zen-browser" system "twilight"];
      };

      "zen-beta" = {
        pkgs,
        system,
        ...
      }: {
        cmd = "zen-beta";
        pkg = pkgs.zen-browser or null;
        inputPath = ["zen-browser" system "beta"];
      };

      chromium = {pkgs, ...}: {
        cmd = "chromium";
        pkg = pkgs.chromium;
        inputPath = null;
      };

      chrome = {pkgs, ...}: {
        cmd = "google-chrome-stable";
        pkg = pkgs.google-chrome;
        inputPath = null;
      };

      edge = {pkgs, ...}: {
        cmd = "microsoft-edge";
        pkg = pkgs.microsoft-edge;
        inputPath = null;
      };

      brave = {pkgs, ...}: {
        cmd = "brave";
        pkg = pkgs.brave;
        inputPath = null;
      };

      vivaldi = {pkgs, ...}: {
        cmd = "vivaldi";
        pkg = pkgs.vivaldi;
        inputPath = null;
      };

      floorp = {pkgs, ...}: {
        cmd = "floorp";
        pkg = pkgs.floorp;
        inputPath = null;
      };
    };
  };

  bars = mkApp {
    defaultApp = "waybar";
    appMap = {
      waybar = {pkgs, ...}: {
        cmd = "waybar";
        pkg = pkgs.waybar;
        inputPath = null;
      };

      noctalia = {
        pkgs,
        system,
        ...
      }: {
        cmd = "noctalia";
        pkg = pkgs.noctalia or null;
        # Uses specialArgs.inputs.packages.noctalia-shell
        inputPath = ["noctalia-shell" system "default"];
      };

      "noctalia-shell" = {
        pkgs,
        system,
        ...
      }: {
        cmd = "noctalia";
        pkg = pkgs.noctalia or null;
        inputPath = ["noctalia-shell" system "default"];
      };

      "dank-material-shell" = {
        pkgs,
        system,
        ...
      }: {
        cmd = "dank-material-shell";
        pkg = pkgs.dankMaterialShell or null;
        inputPath = ["dankMaterialShell" system "default"];
      };

      ags = {pkgs, ...}: {
        cmd = "ags";
        pkg = pkgs.ags;
        inputPath = null;
      };

      yambar = {pkgs, ...}: {
        cmd = "yambar";
        pkg = pkgs.yambar;
        inputPath = null;
      };

      eww = {pkgs, ...}: {
        cmd = "eww";
        pkg = pkgs.eww;
        inputPath = null;
      };
    };
  };

  terminals = mkApp {
    defaultApp = "foot";
    appMap = {
      foot = {pkgs, ...}: {
        cmd = "foot";
        pkg = pkgs.foot;
        inputPath = null;
      };

      alacritty = {pkgs, ...}: {
        cmd = "alacritty";
        pkg = pkgs.alacritty;
        inputPath = null;
      };

      kitty = {pkgs, ...}: {
        cmd = "kitty";
        pkg = pkgs.kitty;
        inputPath = null;
      };

      wezterm = {pkgs, ...}: {
        cmd = "wezterm";
        pkg = pkgs.wezterm;
        inputPath = null;
      };

      "warp-terminal" = {pkgs, ...}: {
        cmd = "warp-terminal";
        pkg = pkgs.warp-terminal;
        inputPath = null;
      };

      ghostty = {pkgs, ...}: {
        cmd = "ghostty";
        pkg = pkgs.ghostty;
        inputPath = null;
      };

      rio = {pkgs, ...}: {
        cmd = "rio";
        pkg = pkgs.rio;
        inputPath = null;
      };
    };
  };

  launchers = mkApp {
    defaultApp = "fuzzel";
    appMap = {
      fuzzel = {pkgs, ...}: {
        cmd = "fuzzel";
        pkg = pkgs.fuzzel;
        inputPath = null;
      };

      wofi = {pkgs, ...}: {
        cmd = "wofi";
        pkg = pkgs.wofi;
        inputPath = null;
      };

      rofi = {pkgs, ...}: {
        cmd = "rofi";
        pkg = pkgs.rofi;
        inputPath = null;
      };

      tofi = {pkgs, ...}: {
        cmd = "tofi";
        pkg = pkgs.tofi;
        inputPath = null;
      };

      dmenu = {pkgs, ...}: {
        cmd = "dmenu";
        pkg = pkgs.dmenu;
        inputPath = null;
      };

      ulauncher = {pkgs, ...}: {
        cmd = "ulauncher";
        pkg = pkgs.ulauncher;
        inputPath = null;
      };
    };
  };

  # Editors with tty/gui structure
  editors = let
    editorMap = {
      helix = {pkgs, ...}: {
        cmd = "hx";
        pkg = pkgs.helix;
        inputPath = null; #? Helix is in nixpkgs
      };

      neovim = {
        pkgs,
        system,
        ...
      }: {
        cmd = "nvim";
        pkg = pkgs.neovim;
        inputPath = ["nvf" system "default"];
      };

      vim = {pkgs, ...}: {
        cmd = "vim";
        pkg = pkgs.vim;
        inputPath = null;
      };

      nano = {pkgs, ...}: {
        cmd = "nano";
        pkg = pkgs.nano;
        inputPath = null;
      };

      emacs = {pkgs, ...}: {
        cmd = "emacs";
        pkg = pkgs.emacs;
        inputPath = null;
      };

      vscode = {pkgs, ...}: {
        cmd = "code";
        pkg = pkgs.vscode-fhs;
        inputPath = null;
      };

      vscodium = {pkgs, ...}: {
        cmd = "codium";
        pkg = pkgs.vscodium;
        inputPath = null;
      };

      zed = {pkgs, ...}: {
        cmd = "zeditor";
        pkg = pkgs.zed-editor-fhs;
        inputPath = null;
      };

      sublime = {pkgs, ...}: {
        cmd = "subl";
        pkg = pkgs.sublime4;
        inputPath = null;
      };
    };

    info = {
      pkgs,
      inputs ? {},
      system ? "x86_64-linux",
      name,
    }: let
      appInfo = editorMap.${name} or null;
    in
      if appInfo != null
      then
        if builtins.isFunction appInfo
        then appInfo {inherit pkgs inputs system;}
        else appInfo
      else {
        cmd = name;
        pkg = null;
        inputPath = null;
      };

    packages = {
      pkgs,
      inputs ? {},
      system ? "x86_64-linux",
      editorConfig ? {},
    }: let
      ttyPrimary = attrByPath ["tty" "primary"] "helix" editorConfig;
      ttySecondary = attrByPath ["tty" "secondary"] null editorConfig;
      guiPrimary = attrByPath ["gui" "primary"] null editorConfig;
      guiSecondary = attrByPath ["gui" "secondary"] null editorConfig;

      getInfo = name:
        if name != null
        then info {inherit pkgs inputs system name;}
        else null;

      allInfos = filter (i: i != null) [
        (getInfo ttyPrimary)
        (getInfo ttySecondary)
        (getInfo guiPrimary)
        (getInfo guiSecondary)
      ];

      getPkg = i:
        if i.inputPath != null
        then
          if hasAttrByPath i.inputPath inputs
          then attrByPath i.inputPath null inputs
          else i.pkg
        else i.pkg;

      allPkgs = map getPkg allInfos;
    in
      unique (filter (p: p != null) allPkgs);

    commands = {
      pkgs,
      inputs ? {},
      system ? "x86_64-linux",
      editorConfig ? {},
    }: let
      ttyPrimary = attrByPath ["tty" "primary"] "helix" editorConfig;
      guiPrimary = attrByPath ["gui" "primary"] null editorConfig;

      ttyInfo = info {
        inherit pkgs inputs system;
        name = ttyPrimary;
      };
      guiInfo =
        if guiPrimary != null
        then
          info {
            inherit pkgs inputs system;
            name = guiPrimary;
          }
        else ttyInfo;
    in {
      editor = ttyInfo.cmd;
      visual = guiInfo.cmd;
    };
  in {
    inherit info packages commands;
  };

  exports = {
    inherit mkApp detectBrowserVariant browsers terminals launchers bars editors;
  };
in
  exports // {_rootAliases = exports;}
