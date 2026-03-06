{
  _,
  lib,
  ...
}: let
  inherit (_.lists.predicates) isIn;
  inherit (lib.attrsets) isAttrs mapAttrs;
  inherit (lib.strings) hasInfix;
  inherit (_.modules.home.mod) mkModule;

  appsAllowed = user: user.applications.allowed or [];

  mkModuleApps = user: {
    #| Plasma Desktop Environment
    plasma = let
      name = "plasma";
      alt = "kde";
    in {
      isAllowed =
        hasInfix name (user.interface.desktopEnvironment or "")
        || hasInfix alt (user.interface.desktopEnvironment or "");
      module = mkModule {inherit name;};
    };

    #| Caelestia Shell
    catppuccin = let
      name = "catppuccin";
      theme = user.interface.style.theme or {};
    in {
      isAllowed =
        isIn name (appsAllowed user)
        || hasInfix name (theme.light or "")
        || hasInfix name (theme.dark or "");
      module = mkModule {inherit name;};
    };

    #| Caelestia Shell
    caelestia = let
      name = "caelestia";
    in {
      isAllowed = isIn ["${name}-shell" name] (
        (appsAllowed user)
        ++ [(user.applications.bar or null)]
      );
      module = mkModule {inherit name;};
    };

    #| Dank Material Shell
    dank-material-shell = let
      name = "dank-material-shell";
    in {
      isAllowed = isIn [name "dank" "dms"] (
        (appsAllowed user)
        ++ [(user.applications.bar or null)]
      );
      module = mkModule {inherit name;};
    };

    #| Noctalia Shell
    noctalia-shell = let
      name = "noctalia-shell";
    in {
      isAllowed = isIn ["noctalia-shell" "noctalia" "noctalia-dev"] (
        (appsAllowed user)
        ++ [(user.applications.bar or null)]
      );
      module = mkModule {inherit name;};
    };

    #| NVF (Neovim Framework)
    nvf = let
      name = "nvf";
    in {
      isAllowed = isIn [name "nvim" "neovim"] (
        (appsAllowed user)
        ++ [(user.applications.editor.tty.primary or null)]
        ++ [(user.applications.editor.tty.secondary or null)]
      );
      module = mkModule {inherit name;};
    };

    #| Firefox - Zen Browser
    zen-browser = let
      name = "zen-browser";
      alt = "zen";
      alt_names = [name alt "zen-twilight"];
      variant =
        if hasInfix "twilight" (user.applications.browser.firefox or "")
        then "twilight"
        else "default";
    in {
      isAllowed =
        hasInfix alt (user.applications.browser.firefox or "")
        || isIn alt_names (appsAllowed user);
      module = mkModule {inherit name variant;};
    };
  };

  mkPrograms = {
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
    tuiApps = ["yazi" "btop" "htop" "fend"];

    #> Resolve the primary terminal command
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
      if (isIn name tuiApps)
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

  exports = {inherit mkPrograms;};
in
  exports // {_rootAliases = {mkUserApps = mkPrograms;};}
