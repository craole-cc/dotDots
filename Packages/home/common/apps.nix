{
  host,
  lib,
  pkgs,
  user,
  ...
}: let
  inherit (lib.attrsets) isAttrs mapAttrs mapAttrsToList;
  inherit (lib.lists) findFirst;
  inherit (lib.strings) hasInfix replaceStrings;

  # Centralized mapping configurations
  commandMappings = {
    terminal = {
      foot = "feet";
    };
    browser = {
      "zen.*twilight" = "zen-twilight";
      "zen.*" = "zen-beta";
      ".*edge" = "microsoft-edge";
    };
    editor = {
      ".*code" = "code";
      ".*zed" = "zeditor";
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
    ".*fuzzel.*" = "fuzzel";
    ".*vicinae.*" = "vicinae";
  };

  # Helper to match patterns
  matchPattern = name: pattern:
    if hasInfix ".*" pattern
    then hasInfix (replaceStrings [".*"] [""] pattern) name
    else name == pattern;

  # Find matching mapping using pattern matching
  findMapping = mappings: name:
    findFirst
    (entry: matchPattern name entry.pattern)
    {
      pattern = name;
      value = name;
    }
    (mapAttrsToList (pattern: value: {inherit pattern value;}) mappings);

  # Get command name based on category and name
  getCommand = category: name:
    if commandMappings ? ${category}
    then (findMapping commandMappings.${category} name).value
    else name;

  # Get class name based on command
  getClass = command:
    (findMapping classMappings command).value;

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
      secondary = "microsoft-edge";
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
}
