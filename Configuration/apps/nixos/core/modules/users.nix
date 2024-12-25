{
  specialArgs,
  lib,
  config,
  ...
}:
let
  # inherit (specialArgs) users;
  inherit (specialArgs) paths host modules;
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.lists)
    foldl'
    filter
    ;
  inherit (lib.modules) mkIf;
  inherit (config.networking) networkmanager;

  allowHomeManager = host.applications.home-manager.enable or false;

  #@ Import user configurations for enabled users
  enabledUsers = map (user: user.name) (filter (user: user.enable or true) host.people);
  users = foldl' (
    acc: userFile: acc // import (paths.core.configurations.users + "/${userFile}")
  ) { } enabledUsers;
in
{
  users.users = mapAttrs (name: user: {
    uid = user.id;
    description = user.description or name;
    isNormalUser = user.isNormalUser or true;
    hashedPassword = user.hashedPassword or null;
    extraGroups = (
      if user.isNormalUser or true then
        [ "users" ]
        ++ (if user.isAdminUser or false then [ "wheel" ] else [ ])
        ++ (if networkmanager.enable or false then [ "networkmanager" ] else [ ])
      else
        [ ]
    );
  }) users;
  home-manager = mkIf allowHomeManager {
    backupFileExtension = "BaC";
    extraSpecialArgs = specialArgs;
    sharedModules = modules.home;
    useUserPackages = true;
    useGlobalPkgs = true;
    users = mapAttrs (
      _: user:
      { osConfig, ... }:
      {
        home = { inherit (osConfig.system) stateVersion; };
        wayland.windowManager.hyprland = {
          enable = user.desktop.manager or null == "hyprland";
        };
      }
    ) users;
    verbose = true;
  };
  # users = {
  #   users = mapAttrs (
  #     name: u: with u; {
  #       inherit
  #         description
  #         isNormalUser
  #         hashedPassword
  #         shell
  #         ;
  #       uid = id;
  #       extraGroups = groups ++ extraGroups;
  #       useDefaultShell = elem shell [
  #         null
  #         config.users.defaultUserShell
  #       ];
  #     }
  #   ) (filterAttrs (_: u: u.enable == true) users);
  # };
}
