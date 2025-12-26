{lib, ...}: let
  inherit (lib.attrsets) attrByPath;
  inherit (lib.lists) filter unique;

  /**
  mkApp - Create a generic application handler

  # Arguments
  - appMap: Attribute set mapping app names to functions that return {cmd, pkg}
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
      name,
    }:
      if builtins.hasAttr name appMap
      then appMap.${name} pkgs
      else {
        cmd = name;
        pkg = null;
      };

    packages = {
      pkgs,
      appConfig ? {},
    }: let
      primary = attrByPath ["primary"] defaultApp appConfig;
      secondary = attrByPath ["secondary"] null appConfig;

      getInfo = name:
        if name != null
        then info {inherit pkgs name;}
        else null;

      allInfos = filter (i: i != null) [
        (getInfo primary)
        (getInfo secondary)
      ];

      allPkgs = map (i: i.pkg) allInfos;
    in
      unique (filter (p: p != null) allPkgs);

    commands = {
      pkgs,
      appConfig ? {},
    }: let
      primary = attrByPath ["primary"] defaultApp appConfig;
      secondary = attrByPath ["secondary"] null appConfig;

      primaryInfo =
        if primary != null
        then
          info {
            inherit pkgs;
            name = primary;
          }
        else null;
      secondaryInfo =
        if secondary != null
        then
          info {
            inherit pkgs;
            name = secondary;
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

  # Application Maps
  browsers = mkApp {
    defaultApp = "firefox";
    appMap = {
      firefox = pkgs: {
        cmd = "firefox";
        pkg = pkgs.firefox;
      };
      zen = pkgs: {
        cmd = "zen";
        pkg = pkgs.zen-browser;
      };
      chromium = pkgs: {
        cmd = "chromium";
        pkg = pkgs.chromium;
      };
      chrome = pkgs: {
        cmd = "google-chrome-stable";
        pkg = pkgs.google-chrome;
      };
      edge = pkgs: {
        cmd = "microsoft-edge";
        pkg = pkgs.microsoft-edge;
      };
      brave = pkgs: {
        cmd = "brave";
        pkg = pkgs.brave;
      };
      vivaldi = pkgs: {
        cmd = "vivaldi";
        pkg = pkgs.vivaldi;
      };
      floorp = pkgs: {
        cmd = "floorp";
        pkg = pkgs.floorp;
      };
    };
  };

  terminals = mkApp {
    defaultApp = "foot";
    appMap = {
      foot = pkgs: {
        cmd = "foot";
        pkg = pkgs.foot;
      };
      alacritty = pkgs: {
        cmd = "alacritty";
        pkg = pkgs.alacritty;
      };
      kitty = pkgs: {
        cmd = "kitty";
        pkg = pkgs.kitty;
      };
      wezterm = pkgs: {
        cmd = "wezterm";
        pkg = pkgs.wezterm;
      };
      warp-terminal = pkgs: {
        cmd = "warp-terminal";
        pkg = pkgs.warp-terminal;
      };
      ghostty = pkgs: {
        cmd = "ghostty";
        pkg = pkgs.ghostty;
      };
      rio = pkgs: {
        cmd = "rio";
        pkg = pkgs.rio;
      };
    };
  };

  launchers = mkApp {
    defaultApp = "fuzzel";
    appMap = {
      fuzzel = pkgs: {
        cmd = "fuzzel";
        pkg = pkgs.fuzzel;
      };
      wofi = pkgs: {
        cmd = "wofi";
        pkg = pkgs.wofi;
      };
      rofi = pkgs: {
        cmd = "rofi";
        pkg = pkgs.rofi;
      };
      tofi = pkgs: {
        cmd = "tofi";
        pkg = pkgs.tofi;
      };
      dmenu = pkgs: {
        cmd = "dmenu";
        pkg = pkgs.dmenu;
      };
      ulauncher = pkgs: {
        cmd = "ulauncher";
        pkg = pkgs.ulauncher;
      };
    };
  };

  bars = mkApp {
    defaultApp = "waybar";
    appMap = {
      waybar = pkgs: {
        cmd = "waybar";
        pkg = pkgs.waybar;
      };
      noctalia = pkgs: {
        cmd = "noctalia";
        pkg = pkgs.noctalia;
      };
      ags = pkgs: {
        cmd = "ags";
        pkg = pkgs.ags;
      };
      yambar = pkgs: {
        cmd = "yambar";
        pkg = pkgs.yambar;
      };
      eww = pkgs: {
        cmd = "eww";
        pkg = pkgs.eww;
      };
    };
  };

  # Editors is special with tty/gui structure
  editors = let
    info = {
      pkgs,
      name,
    }:
      {
        helix = {
          cmd = "hx";
          pkg = pkgs.helix;
        };
        neovim = {
          cmd = "nvim";
          pkg = pkgs.neovim;
        };
        vim = {
          cmd = "vim";
          pkg = pkgs.vim;
        };
        nano = {
          cmd = "nano";
          pkg = pkgs.nano;
        };
        emacs = {
          cmd = "emacs";
          pkg = pkgs.emacs;
        };
        vscode = {
          cmd = "code";
          pkg = pkgs.vscode;
        };
        "vscode-insiders" = {
          cmd = "code-insiders";
          pkg = pkgs.vscode-insiders;
        };
        vscodium = {
          cmd = "codium";
          pkg = pkgs.vscodium;
        };
        zed = {
          cmd = "zeditor";
          pkg = pkgs.zed-editor;
        };
        sublime = {
          cmd = "subl";
          pkg = pkgs.sublime4;
        };
        atom = {
          cmd = "atom";
          pkg = pkgs.atom;
        };
      }.${
        name
      } or {
        cmd = name;
        pkg = null;
      };

    packages = {
      pkgs,
      editorConfig ? {},
    }: let
      ttyPrimary = attrByPath ["tty" "primary"] "helix" editorConfig;
      ttySecondary = attrByPath ["tty" "secondary"] null editorConfig;
      guiPrimary = attrByPath ["gui" "primary"] null editorConfig;
      guiSecondary = attrByPath ["gui" "secondary"] null editorConfig;

      getInfo = name:
        if name != null
        then info {inherit pkgs name;}
        else null;

      allInfos = filter (i: i != null) [
        (getInfo ttyPrimary)
        (getInfo ttySecondary)
        (getInfo guiPrimary)
        (getInfo guiSecondary)
      ];

      allPkgs = map (i: i.pkg) allInfos;
    in
      unique (filter (p: p != null) allPkgs);

    commands = {
      pkgs,
      editorConfig ? {},
    }: let
      ttyPrimary = attrByPath ["tty" "primary"] "helix" editorConfig;
      guiPrimary = attrByPath ["gui" "primary"] null editorConfig;

      ttyInfo = info {
        inherit pkgs;
        name = ttyPrimary;
      };
      guiInfo =
        if guiPrimary != null
        then
          info {
            inherit pkgs;
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
    inherit mkApp browsers terminals launchers bars editors;
  };
in
  exports // {_rootAliases = exports;}
