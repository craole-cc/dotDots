{
  host,
  lib,
  lix,
  user,
  mkMerge,
  ...
}: let
  inherit (lib.strings) hasInfix toUpper;

  args = {
    inherit
      host
      lib
      lix
      mkMerge
      user
      ;
    mod = toUpper (
      user.interface.keyboard.modifier or
        host.interface.keyboard.modifier or
        "Super"
    );

    cmd = let
      mkCmd = {
        category,
        field,
        default,
        defaultClass ? null,
      }: let
        apps = user.applications or {};
        name = apps.${category}.${field} or default;

        # Determine the command to execute
        command =
          if category == "terminal"
          then
            if name == "foot"
            then "footclient"
            else name
          else if category == "browser"
          then
            if hasInfix "zen" name
            then
              if hasInfix "twilight" name
              then "zen-twilight"
              else "zen-beta"
            else if hasInfix "edge" name
            then "microsoft-edge"
            else name
          else if category == "editor"
          then
            if hasInfix "code" name
            then "code"
            else if hasInfix "zed" name
            then "zeditor"
            else name
          else if category == "launcher"
          then
            if name == "vicinae"
            then "vicinae toggle"
            else if name == "fuzzel"
            then "pkill fuzzel || fuzzel --list-executables-in-path"
            else name
          else name;

        # Determine the window class
        windowClass =
          if category == "terminal"
          then
            if name == "foot"
            then "foot"
            else if name == "ghostty"
            then "com.mitchellh.ghostty"
            else name
          else if category == "browser"
          then command # browser commands match their classes
          else if category == "editor"
          then
            if hasInfix "code" name
            then "code"
            else if hasInfix "zed" name
            then "dev.zed.Zed"
            else name
          else command;
      in {
        inherit command;
        class = windowClass;
      };
    in {
      browser = {
        primary = mkCmd {
          category = "browser";
          field = "primary";
          default = "zen-twilight";
        };
        secondary = mkCmd {
          category = "browser";
          field = "secondary";
          default = "microsoft-edge";
        };
      };
      editor = {
        primary = mkCmd {
          category = "editor";
          field = "gui.primary";
          default = "vscode";
        };
        secondary = mkCmd {
          category = "editor";
          field = "gui.secondary";
          default = "zed";
        };
      };
      launcher = {
        primary = mkCmd {
          category = "launcher";
          field = "primary";
          default = "vicinae";
        };
        secondary = mkCmd {
          category = "launcher";
          field = "secondary";
          default = "fuzzel";
        };
      };
      terminal = {
        primary = mkCmd {
          category = "terminal";
          field = "primary";
          default = "foot";
        };
        secondary = mkCmd {
          category = "terminal";
          field = "secondary";
          default = "ghostty";
        };
      };
    };

    swapCapsEscape =
      user.interface.keyboard.swapCapsEscape or
        host.interface.keyboard.swapCapsEscape or
        null;
  };
in {
  settings = mkMerge [
    (import ./core.nix {inherit args;})
    (import ./io.nix {inherit args;})
    # (import ./startup.nix)
    # (import ./rules.nix {inherit lib;})
    (import ./workspaces.nix {inherit args;})
  ];
}
