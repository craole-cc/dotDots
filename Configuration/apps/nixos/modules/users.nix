{
  specialArgs,
  lib,
  config,
  ...
}:
let
  inherit (specialArgs) host modules;
  inherit (host) userConfigs;
  inherit (lib.attrsets) mapAttrs attrValues;
  inherit (lib.lists) any;
  inherit (config.networking) networkmanager;

  #@ Define the users configuration
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

  #@ Define the home-manager configuration
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
        home = { inherit (osConfig.system) stateVersion; };
        programs = {
          home-manager.enable = user.applications.home-manager.enable or false;
        };
        wayland.windowManager.hyprland = {
          enable = user.desktop.manager or null == "hyprland";
        };

      }
    ) userConfigs;
    verbose = true;
  };
in
{
  config =
    { }
    // (if userConfigs != { } then { inherit users; } else { })
    // (if allowHomeManager then { inherit home-manager; } else { });
}
