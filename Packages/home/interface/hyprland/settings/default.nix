{
  host,
  lib,
  user,
  lix,
  mkMerge,
  ...
}:
let
  inherit (lib.strings) hasInfix toUpper;

  mkCmd =
    category: field: default:
    let
      apps = user.applications or { };
      name = apps.${category}.${field} or default;
    in
    if category == "terminal" then
      if name == "foot" then "footclient" else name
    else if category == "browser" then
      if hasInfix "zen" name then
        if hasInfix "twilight" name then "zen-twilight" else "zen-beta"
      else if hasInfix "edge" name then
        "microsoft-edge"
      else
        name
    else if category == "editor" then
      if hasInfix "code" name then
        "code"
      else if hasInfix "zed" name then
        "zeditor"
      else
        name
    else if category == "launcher" then
      if name == "vicinae" then
        "vicinae toggle"
      else if name == "fuzzel" then
        "pkill fuzzel || fuzzel --list-executables-in-path"
      else
        name
    else
      name;

  args = {
    inherit user host lib;

    mod = toUpper (user.interface.keyboard.modifier or host.interface.keyboard.modifier or "Super");

    cmd = {
      browser = {
        primary = mkCmd "browser" "primary" "zen-twilight";
        secondary = mkCmd "browser" "secondary" "microsoft-edge";
      };
      editor = {
        primary = mkCmd "editor" "gui.primary" "vscode";
        secondary = mkCmd "editor" "gui.secondary" "zed";
      };
      launcher = {
        primary = mkCmd "launcher" "primary" "vicinae";
        secondary = mkCmd "launcher" "secondary" "fuzzel";
      };
      terminal = {
        primary = mkCmd "terminal" "primary" "foot";
        secondary = mkCmd "terminal" "secondary" "ghostty";
      };
    };

    swapCapsEscape =
      user.interface.keyboard.swapCapsEscape or host.interface.keyboard.swapCapsEscape or null;

  };
in
{
  settings = mkMerge [
    (import ./core.nix { inherit args; })
    (import ./io.nix { inherit args; })
    # (import ./startup.nix)
    # (import ./rules.nix {inherit lib;})
    (import ./workspaces.nix { inherit args; })
  ];
}
