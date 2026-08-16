{_, ...}: let
  inherit (_.attrsets.access) attrByPath;
  inherit (_.attrsets.predicates) hasAttrByPath;
  inherit (_.lists.predicates) all;
  inherit (_.lists.selection) filter;
  inherit (_.lists.transformation) unique;
  inherit (_.lists.aggregation) concatMap;
  inherit (_.applications.registry) resolve;
  inherit (_.applications.runtime) resolvePackage;
  inherit (_.types.predicates) isFunction isList;

  /**
  mkapp - create a generic application handler with flake support

  # arguments
  - appmap: attribute set mapping app names to functions that return {cmd, pkg, inputpath}
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
      system ? "x86_64-linux", #TODO: use getSystemOrDefault {}
      name,
    }: let
      app = appMap.${name} or null;
    in
      if app != null
      then
        if isFunction app
        then app {inherit pkgs inputs system;}
        else app
      else {
        cmd = name;
        pkg = null;
        inputPath = null;
      };

    packages = {
      pkgs,
      inputs ? {},
      system ? "x86_64-linux",
      config ? {},
    }: let
      primary = attrByPath ["primary"] defaultApp config;
      secondary = attrByPath ["secondary"] null config;

      # Normalize user input first
      normalizedPrimary = primary;
      normalizedSecondary = secondary;

      getInfo = name:
        if name != null
        then
          info {
            inherit
              pkgs
              inputs
              system
              name
              ;
          }
        else null;

      allInfos = filter (i: i != null) [
        (getInfo normalizedPrimary)
        (getInfo normalizedSecondary)
      ];

      # Try input path first (from specialArgs), then pkg
      getPkg = i: let
        inputPath = normalizeInputPath i.inputPath;
      in
        if inputPath != null
        then
          if hasAttrByPath inputPath inputs
          then attrByPath inputPath null inputs
          else i.pkg
        else i.pkg;

      allPkgs = map getPkg allInfos;
    in
      unique (filter (p: p != null) allPkgs);

    commands = {
      pkgs,
      inputs ? {},
      system ? "x86_64-linux",
      config ? {},
    }: let
      primary = attrByPath ["primary"] defaultApp config;
      secondary = attrByPath ["secondary"] null config;

      # Normalize user input first
      normalizedPrimary = primary;
      normalizedSecondary = secondary;

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

  # Compatibility shim: application identity is resolved by the registry.
  detectBrowserVariant = input: input;

  normalizeInputPath = path:
    if path == null
    then null
    else if builtins.isString path
    then [path]
    else if isList path
    then let
      flattened = concatMap (segment:
        if isList segment
        then segment
        else [segment])
      path;
    in
      if all builtins.isString flattened
      then flattened
      else null
    else null;

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
        inputs ? {},
        system ? "x86_64-linux",
        ...
      }: let
        app = resolve {
          value = "zen-twilight";
          category = "browser";
        };
      in {
        cmd = app.exec or app.names.command or "zen";
        pkg = resolvePackage {inherit app pkgs inputs system;};
        inputPath = null;
      };

      "zen-beta" = {
        pkgs,
        inputs ? {},
        system ? "x86_64-linux",
        ...
      }: let
        app = resolve {
          value = "zen-beta";
          category = "browser";
        };
      in {
        cmd = app.exec or app.names.command or "zen";
        pkg = resolvePackage {inherit app pkgs inputs system;};
        inputPath = null;
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
        inputPath = [
          "noctalia-shell"
          system
          "default"
        ];
      };

      "noctalia-shell" = {
        pkgs,
        system,
        ...
      }: {
        cmd = "noctalia";
        pkg = pkgs.noctalia or null;
        inputPath = [
          "noctalia-shell"
          system
          "default"
        ];
      };

      "dank-material-shell" = {
        pkgs,
        system,
        ...
      }: {
        cmd = "dank-material-shell";
        pkg = pkgs.dankMaterialShell or null;
        inputPath = [
          "dankMaterialShell"
          system
          "default"
        ];
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

  editors = let
    editorMap = {
      helix = {pkgs, ...}: {
        cmd = "hx";
        pkg = pkgs.helix;
        inputPath = null; # ? Helix is in nixpkgs
      };

      neovim = {
        pkgs,
        system,
        ...
      }: {
        cmd = "nvim";
        pkg = pkgs.neovim;
        inputPath = [
          "nvf"
          system
          "default"
        ];
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
      app = editorMap.${name} or null;
    in
      if app != null
      then
        if isFunction app
        then app {inherit pkgs inputs system;}
        else app
      else {
        cmd = name;
        pkg = null;
        inputPath = null;
      };

    packages = {
      pkgs,
      inputs ? {},
      system ? "x86_64-linux",
      config ? {},
    }: let
      ttyPrimary = attrByPath ["tty" "primary"] "helix" config;
      ttySecondary = attrByPath ["tty" "secondary"] null config;
      guiPrimary = attrByPath ["gui" "primary"] null config;
      guiSecondary = attrByPath ["gui" "secondary"] null config;

      getInfo = name:
        if name != null
        then
          info {
            inherit
              pkgs
              inputs
              system
              name
              ;
          }
        else null;

      allInfos = filter (i: i != null) [
        (getInfo ttyPrimary)
        (getInfo ttySecondary)
        (getInfo guiPrimary)
        (getInfo guiSecondary)
      ];

      getPkg = i: let
        inputPath = normalizeInputPath i.inputPath;
      in
        if inputPath != null
        then
          if hasAttrByPath inputPath inputs
          then attrByPath inputPath null inputs
          else i.pkg
        else i.pkg;

      allPkgs = map getPkg allInfos;
    in
      unique (filter (p: p != null) allPkgs);

    commands = {
      pkgs,
      inputs ? {},
      system ? "x86_64-linux",
      config ? {},
    }: let
      ttyPrimary = attrByPath ["tty" "primary"] "helix" config;
      guiPrimary = attrByPath ["gui" "primary"] null config;

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
    inherit
      mkApp
      detectBrowserVariant
      browsers
      terminals
      launchers
      bars
      editors
      ;
  };
in
  exports // {__rootAliases = exports;}
