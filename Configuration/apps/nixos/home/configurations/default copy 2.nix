{ specialArgs, lib, ... }:
let
  inherit (specialArgs.host) people;
  inherit (lib.attrsets) mapAttrs attrValues genAttrs;
  inherit (lib.lists)
    any
    foldl'
    filter
    length
    head
    ;
  inherit (lib.strings) concatStringsSep;

  # Debug: Print out desktop manager for all people
  debugDesktopManagers = mapAttrs (name: user: user.desktop.manager or "NOT_SET") enabledUsers;

  # Use more descriptive names and leverage Nix's pattern matching
  isEnabledUser = user: user.enable or true;

  isHyprlandUser =
    user:
    let
      result = user.desktop.manager or null == "hyprland";
    in
    # Uncomment for debugging
    # builtins.trace "User: ${user.name or "unknown"}, Desktop Manager: ${user.desktop.manager or "NOT_SET"}, Result: ${builtins.toString result}"
    result;

  # Directly filter and map in one go
  hostUsers = map (user: user.name) (filter isEnabledUser people);

  # Simplify autoLogin logic
  autoLoginUser =
    let
      autoLoginUsers = filter (user: user.autoLogin or false) people;
    in
    if length autoLoginUsers == 1 then (head autoLoginUsers).name else null;

  # Use more functional approach for importing user configurations
  enabledUsers = genAttrs hostUsers (user: import (./. + "/${user}"));
in
{
  # Debug entire configuration
  _module.args.debugConfig = {
    inherit debugDesktopManagers;
    inherit hostUsers;
    enabledUsersKeys = builtins.attrNames enabledUsers;
    hyprlandCheck = any isHyprlandUser (attrValues people);
  };

  # programs.hyprland.enable = any
  #   (user: user.desktop.manager or null == "hyprland")
  #   (attrValues people);

  # users.users = mapAttrs (name: user: {
  #   inherit (user)
  #     description
  #     isNormalUser
  #     hashedPassword
  #     ;
  #   uid = user.id;
  # }) enabledUsers;

  # home-manager.users = mapAttrs (name: user: {
  #   wayland.windowManager.hyprland.enable =
  #     (people.${name}.desktop.manager or null) == "hyprland";
  # }) enabledUsers;
}
