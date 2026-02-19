{
  host,
  lib,
  # pkgs,
  user,
  ...
}: let
  inherit (lib.attrsets) isAttrs mapAttrs;
  # inherit (lib.lists) findFirst;
  inherit (lib.strings) hasInfix;

  # Centralized mapping configurations
  commandMappings = {
    terminal = {
      foot = "feet";
      ghostty = "ghostty";
    };
    browser = {
      zen-twilight = "zen-twilight";
      zen-beta = "zen-beta";
      # microsoft-edge = "microsoft-edge";
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

  # Get command name based on category and name
  getCommand = category: name:
    if commandMappings ? ${category} && commandMappings.${category} ? ${name}
    then commandMappings.${category}.${name}
    else if category == "browser" && hasInfix "zen" name
    then
      if hasInfix "twilight" name
      then "zen-twilight"
      else "zen-beta"
    # else if category == "browser" && hasInfix "edge" name
    # then "microsoft-edge"
    else if category == "editor" && hasInfix "code" name
    then "code"
    else if category == "editor" && hasInfix "zed" name
    then "zeditor"
    else name;

  # Get class name based on command
  getClass = command:
    if classMappings ? ${command}
    then classMappings.${command}
    else if hasInfix "fuzzel" command
    then "fuzzel"
    else if hasInfix "vicinae" command
    then "vicinae"
    else command;

  mkDefault = {
    category,
    option,
    default,
  }: let
    name =
      user.applications.${category}.${option}
      or host.applications.${category}.${option}
      or default;

    command = getCommand category name;
    class = getClass command;
  in {inherit command class;};

  # Simplified category configuration
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
      # secondary = "microsoft-edge";
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
in {
  _module.args.apps =
    mapAttrs mkCategory categoryDefaults
    // {inherit mkDefault;};

  # home.packages = with pkgs; [
  #   foot
  #   ghostty
  # ];
}
