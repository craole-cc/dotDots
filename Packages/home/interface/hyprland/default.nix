{
  user,
  lib,
  lix,
  host,
  ...
}: let
  app = "hyprland";
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.strings) hasInfix;
  isAllowed = app == (user.interface.windowManager or null);
  _apps = user.applications or {};
  apps = {
    terminal = {
      primary = rec {
        name = _apps.terminal.primary or "foot";
        command =
          if name == "foot"
          then "footclient"
          else name;
      };
      secondary = rec {
        name = _apps.terminal.primary or "ghostty";
        command =
          if name == "foot"
          then "footclient"
          else name;
      };
    };
    browser = {
      primary = {
        name = "zen-twilight";
        command = "zen-twilight";
      };
      secondary = {
        name = "microsoft-edge";
        command = "microsoft-edge";
      };
    };
    editor = {
      primary = rec {
        name = _apps.editor.gui.primary or "vscode";
        command =
          if hasInfix "code" name
          then "code"
          else if hasInfix "zed" name
          then "zeditor"
          else name;
      };
      secondary = rec {
        name = _apps.editor.gui.primary or "zed";
        command =
          if hasInfix "code" name
          then "code"
          else if hasInfix "zed" name
          then "zeditor"
          else name;
      };
    };
    launcher = {
      primary = {
        name = "vicinae";
        command = "vicinae toggle";
      };
      secondary = {
        name = "fuzzel";
        command = "pkill fuzzel || fuzzel --list-executables-in-path";
      };
    };
  };
in {
  config = mkIf isAllowed {
    wayland.windowManager.hyprland = mkMerge [
      {enable = true;}
      # (import ./components {inherit mkMerge;})
      (import ./settings {inherit host user apps lib lix;})
      # (import ./submaps)
      # (import ./plugins)
    ];
  };
}
