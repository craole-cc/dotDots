{
  specialArgs,
  lib,
  config,
  ...
}:
let
  # inherit (specialArgs) users;
  inherit (specialArgs) paths host modules;
  inherit (lib.attrsets) mapAttrs attrValues;
  inherit (lib.lists)
    any
    foldl'
    filter
    ;
  inherit (lib.modules) mkIf;
  inherit (config.networking) networkmanager;

  #@ Import user configurations for enabled users
  enabledUsers = map (user: user.name) (filter (user: user.enable or true) host.people);
  userConfigs = foldl' (
    acc: userFile: acc // import (paths.core.configurations.users + "/${userFile}")
  ) { } enabledUsers;

  allowHomeManager =
    host.allowHomeManager
      or (any (user: user.applications.home-manager.enable or false == true) (attrValues userConfigs));

  home-manager = {
    backupFileExtension = host.backupFileExtension or "BaC";
    extraSpecialArgs = specialArgs;
    sharedModules = modules.home;
    useUserPackages = true;
    useGlobalPkgs = true;
    users = mapAttrs (
      _: user:
      { osConfig, ... }:
      {
        home = {
          inherit (osConfig.system) stateVersion;
        };
        programs = { inherit (user.applications) home-manager; };
        wayland.windowManager.hyprland = {
          enable = user.desktop.manager or null == "hyprland";
        };

      }
    ) userConfigs;
    verbose = true;
  };

  users.users = mapAttrs (
    _: user: with user; {
      uid = user.id or null;
      description = user.description or name;
      isNormalUser = user.isNormalUser or true;
      hashedPassword = user.hashedPassword or null;
      extraGroups =
        if user.isNormalUser or true then
          [ "users" ]
          ++ (if user.isAdminUser or false then [ "wheel" ] else [ ])
          ++ (if networkmanager.enable or false then [ "networkmanager" ] else [ ])
        else
          [ ];
    }
  ) userConfigs;
in
{
  _module.args.config =
    {
      inherit userConfigs;
    }
    // (if userConfigs != { } then { inherit users; } else { })
    // (if allowHomeManager then { inherit home-manager; } else { });
}
