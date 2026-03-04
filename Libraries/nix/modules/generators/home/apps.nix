{
  _,
  lib,
  ...
}: let
  inherit (_.lists) isIn;
  inherit (lib.attrsets) isAttrs mapAttrs;
  inherit (lib.strings) hasInfix;

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

  exports = {inherit mkApps;};
in
  exports // {_rootAliases = {mkUserApps = mkApps;};}
