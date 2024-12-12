{ specialArgs, lib, ... }:
let
  inherit (specialArgs.host) people;
  inherit (lib.attrsets) mapAttrs attrValues;
  inherit (lib.lists)
    any
    foldl'
    filter
    length
    head
    ;
  inherit (lib.strings) concatStringsSep;

  # Use more descriptive names and leverage Nix's pattern matching
  isUserEnabled = user: user.enable or true;
  isHyprlandUser = user: user.desktop.manager or null == "hyprland";

  # Directly filter and map in one go
  hostUsers = map (user: user.name) (filter isUserEnabled people);

  # Simplify autoLogin logic
  autoLoginUser =
    let
      autoLoginUsers = filter (user: user.autoLogin or false) people;
    in
    if length autoLoginUsers == 1 then (head autoLoginUsers).name else null;

  # Use more functional approach for importing user configurations
  enabledUsers = lib.genAttrs hostUsers (user: import (./. + "/${user}"));
in
{
  # Use more explicit boolean check
  programs.hyprland.enable = any isHyprlandUser (attrValues enabledUsers);

  users.users = mapAttrs (name: user: {
    inherit (user)
      description
      isNormalUser
      hashedPassword
      ;
    uid = user.id;
  }) enabledUsers;

  home-manager.users = mapAttrs (name: user: {
    wayland.windowManager.hyprland.enable = isHyprlandUser user;
  }) enabledUsers;
}
