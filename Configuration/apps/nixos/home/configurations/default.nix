{ specialArgs, lib, ... }:
let
  #@ Import necessary libs and specialArgs
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

  #@ Filter enabled users based on the 'enable' attribute
  hostUsers = map (user: user.name) (filter (user: user.enable or true) people);

  #@ Check for autoLogin constraints
  autoLoginUsers = filter (user: user.autoLogin or false) people;
  autoLoginUser = if length autoLoginUsers == 1 then (head autoLoginUsers).name else null;

  #@ Import user configurations for enabled users
  enabledUsers = foldl' (acc: user: acc // import (./. + "/${user}")) { } hostUsers;
in
{
  _module.args.debugConfig = {

    programs.hyprland.enable = any (user: user.desktop.manager or null == "hyprland") (
      attrValues enabledUsers
    );

    users.users = mapAttrs (
      name: user: with user; {
        inherit
          description
          isNormalUser
          hashedPassword
          ;
        uid = id;
      }
    ) enabledUsers;

    home-manager = {
      users = mapAttrs (
        name: user:
        { config, ... }:
        {
          wayland.windowManager.hyprland = {
            enable = user.desktop.manager or null == "hyprland";
          };
        }
      ) enabledUsers;
    };
  };
}
