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

    apps = let
      mkCmd = {
        category,
        field,
        default,
        defaultClass ? null,
      }: let
        apps = user.applications or {};
        name = apps.${category}.${field} or default;

        #> Determine the command to execute
        command =
          if category == "terminal"
          then
            if name == "foot"
            then "pgrep -x foot >/dev/null || foot --server >/dev/null 2>&1 & footclient"
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

        #> Determine the window class
        class =
          if command == "footclient"
          then "foot"
          else if command == "ghostty"
          then "com.mitchellh.ghostty"
          else if command == "zeditor"
          then "dev.zed.Zed"
          else if (hasInfix "fuzzel" command)
          then "fuzzel"
          else if (hasInfix "vicinae" command)
          then "vicinae"
          else command;
      in {inherit command class;};
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
