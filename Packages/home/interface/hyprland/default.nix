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

  resolveCommand = category: field: default: let
    name = _apps.${category}.${field} or default;
  in
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

  apps = {
    terminal = {
      primary = resolveCommand "terminal" "primary" "foot";
      secondary = resolveCommand "terminal" "secondary" "ghostty";
    };
    browser = {
      primary = resolveCommand "browser" "primary" "zen-twilight";
      secondary = resolveCommand "browser" "secondary" "microsoft-edge";
    };
    editor = {
      primary = resolveCommand "editor" "gui.primary" "vscode";
      secondary = resolveCommand "editor" "gui.secondary" "zed";
    };
    launcher = {
      primary = resolveCommand "launcher" "primary" "vicinae";
      secondary = resolveCommand "launcher" "secondary" "fuzzel";
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
