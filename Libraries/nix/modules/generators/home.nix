{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) filterAttrs isAttrs mapAttrs removeAttrs;
  inherit (lib.strings) hasInfix toLower toUpper;
  inherit (lib.lists) elem;
  inherit (_.modules.generators.core) userAttrs;
  inherit (_.filesystem.paths) getDefaults;

  /**
  Filter users eligible for home-manager configuration.
  Excludes: service users, guest users, and empty/undefined users.

  Type: AttrSet -> AttrSet

  Example:
    homeManagerUsers { users.data.enabled = {
      alice = { role = "admin"; };
      cc = { role = "service"; };
    }; }
    => { alice = { role = "admin"; }; }
  */
  userAttrs' = host:
    filterAttrs
    (_: user:
      user
      != {} # User must exist
      && (user.role or null) != "service" # Not a system service
      && (user.role or null) != "guest") # Not a guest account
    
    (userAttrs host);

  mkApps = {
    host,
    user,
  }: let
    commandMappings = {
      terminal = {
        foot = "feet";
        ghostty = "ghostty";
      };
      browser = {
        zen-twilight = "zen-twilight";
        zen-beta = "zen-beta";
      };
      editor = {
        vscode = "code";
        zed = "zeditor";
      };
      launcher = {
        vicinae = "vicinae toggle";
        fuzzel = "pkill fuzzel || fuzzel --list-executables-in-path";
      };
    };

    classMappings = {
      feet = "foot";
      ghostty = "com.mitchellh.ghostty";
      zeditor = "dev.zed.Zed";
      fuzzel = "fuzzel";
      vicinae = "vicinae";
    };

    #> List apps that require a terminal wrapper
    tuiApps = ["yazi" "btop" "htop"];

    #> Resolve the primary terminal command once, elegantly
    rawTerm = user.applications.terminal.primary 
    or host.applications.terminal.primary 
    or categoryDefaults.terminal.primary;

    primaryTerminalCmd = commandMappings.terminal.${rawTerm} or rawTerm;

    getCommand = category: name: let
      mappedCmd = commandMappings.${category}.${name} or name;
      resolvedCmd =
        if category == "browser" && hasInfix "zen" name
        then
          (
            if hasInfix "twilight" name
            then "zen-twilight"
            else "zen-beta"
          )
        else if category == "editor" && hasInfix "code" name
        then "code"
        else if category == "editor" && hasInfix "zed" name
        then "zeditor"
        else mappedCmd;
    in
      if (elem name tuiApps)
      then "${primaryTerminalCmd} -e ${resolvedCmd}"
      else resolvedCmd;

    getClass = command: let
      baseClass = classMappings.${command} or command;
    in
      if hasInfix "fuzzel" command
      then "fuzzel"
      else if hasInfix "vicinae" command
      then "vicinae"
      else if hasInfix "yazi" command
      then "yazi"
      else baseClass;

    mkDefault = {
      category,
      option,
      default,
    }: let
      name = user.applications.${category}.${option}
      or host.applications.${category}.${option}
      or default;
      command = getCommand category name;
      class = getClass command;
    in {inherit command class;};

    mkCategory = category: options:
      mapAttrs (
        name: value:
          mkDefault {
            inherit category;
            option =
              if isAttrs value && value ? option
              then value.option
              else name;
            default =
              if isAttrs value
              then value.default or value
              else value;
          }
      )
      options;

    categoryDefaults = {
      browser = {
        primary = "zen-twilight";
        secondary = "chromium";
      };
      editor = {
        primary = {
          option = "gui.primary";
          default = "vscode";
        };
        secondary = {
          option = "gui.secondary";
          default = "zed";
        };
      };
      explorer = {
        primary = "yazi";
        secondary = "org.gnome.Nautilus";
      };
      launcher = {
        primary = "vicinae";
        secondary = "fuzzel";
      };
      terminal = {
        primary = "foot";
        secondary = "ghostty";
      };
    };
  in
    mapAttrs mkCategory categoryDefaults // {inherit mkDefault;};

  mkStyle = {
    host,
    user,
  }: let
    theme = user.interface.style.theme or {};
    mode = toLower (theme.mode or "dark");
    variant = toLower (theme.${mode} or "Catppuccin Latte");
    accent = toLower (theme.accent or "rosewater");
    flavor =
      if hasInfix "frappe" variant || hasInfix "frappé" variant
      then "frappe"
      else if hasInfix "latte" variant
      then "latte"
      else if hasInfix "mocha" variant
      then "mocha"
      else if hasInfix "macchiato" variant
      then "macchiato"
      else if mode == "dark"
      then "frappe"
      else "latte";
    catppuccin = hasInfix "catppuccin" variant;
    fonts =
      user.interface.style.fonts or host.interface.style.fonts or {
        emoji = "Noto Color Emoji";
        monospace = "Maple Mono NF";
        sans = "Monaspace Radon Frozen";
        serif = "Noto Serif";
        material = "Material Symbols Sharp";
        clock = "Rubik";
      };
  in {inherit fonts mode variant accent flavor catppuccin;};

  mkKeyboard = {
    host,
    user,
  }: {
    mod = toUpper (
      user.interface.keyboard.modifier or
      host.interface.keyboard.modifier or
      "Super"
    );
    swapCapsEscape =
      user.interface.keyboard.swapCapsEscape or
      host.interface.keyboard.swapCapsEscape or
      null;
    vimKeybinds =
      user.interface.keyboard.vimKeybinds or
      host.interface.keyboard.vimKeybinds or
      false;
  };

  mkLocale = {host}: let
    loc = host.localization or {};
  in {
    city = loc.city or "Mandeville, Jamaica";
    timeZone = loc.timeZone or "America/Jamaica";
    defaultLocale = loc.defaultLocale or "en_US.UTF-8";
    locator = loc.locator or "geoclue2";
    latitude = loc.latitude or 18.015;
    longitude = loc.longitude or (-77.49);
  };

  /**
  Produces the entire home-manager NixOS option block for all eligible users.
  Type: { host, specialArgs, paths } -> AttrSet
  */
  mkUsers = {
    host,
    specialArgs,
    mkHomeModuleApps,
    paths,
  }: {
    home-manager = {
      backupFileExtension = "BaC";
      overwriteBackup = true;
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs =
        (removeAttrs specialArgs ["paths"])
        // {
          lix = _;
          inherit host;
        };

      users =
        mapAttrs (
          name: user: {
            nixosConfig,
            config,
            pkgs,
            ...
          }: let
            inputsForHome = mkHomeModuleApps {inherit user;};
            derivedPaths = getDefaults {inherit config host user pkgs paths;};
          in {
            _module.args = {
              style = mkStyle {inherit host user;};
              user = user // {inherit name;};
              apps = mkApps {inherit host user;};
              keyboard = mkKeyboard {inherit host user;};
              locale = mkLocale {inherit host;};
              paths = derivedPaths;
              inherit inputsForHome;
            };

            home = {inherit (nixosConfig.system) stateVersion;};

            imports =
              []
              ++ [paths.store.pkgs.home]
              ++ (user.imports or [])
              ++ (with inputsForHome; [
                caelestia.module
                catppuccin.module
                dank-material-shell.module
                noctalia-shell.module
                nvf.module
                plasma.module
                zen-browser.module
              ]);
          }
        )
        (userAttrs' host);
    };
  };

  exports = {
    inherit
      mkApps
      mkKeyboard
      mkLocale
      mkStyle
      mkUsers
      ;
    userAttrs = userAttrs';
  };
in
  exports
  // {
    _rootAliases = {
      homeUserAttrs = userAttrs';
      mkHomeUserApps = mkApps;
      mkHomeUserKeyboard = mkKeyboard;
      mkHomeUserLocale = mkLocale;
      mkHomeUserStyle = mkStyle;
      mkHomeUsers = mkUsers;
    };
  }
