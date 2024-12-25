{
  specialArgs,
  lib,
  config,
  ...
}:
let
  inherit (specialArgs) host modules;
  inherit (host) userConfigs people;
  inherit (lib.attrsets)
    mapAttrs
    attrValues
    attrNames
    filterAttrs
    ;
  inherit (lib.lists)
    any
    filter
    unique
    elem
    ;
  inherit (config.networking) networkmanager;

  enabledUsers = filter (user: user.enable or true) people;
  regularUsersPerHost = map (user: user.name) (
    filter (user: user.admin or false == false) enabledUsers
  );
  elevatedUsersPerHostConf = map (user: user.name) (
    filter (user: user.admin or false == true) enabledUsers
  );
  elevatedUsersPerUserConf = attrNames (filterAttrs (_: user: user.isAdminUser or false) userConfigs);
  elevatedUsers = unique (
    filter (user: !elem user regularUsersPerHost) (elevatedUsersPerHostConf ++ elevatedUsersPerUserConf)
  );

  #@ Define the users configuration
  users.users = mapAttrs (name: user: {
    uid = user.id or null;
    description = user.description or name;
    isNormalUser = user.isNormalUser or true;
    hashedPassword = user.hashedPassword or null;
    extraGroups =
      if user.isNormalUser or true then
        [ "users" ]
        ++ (if elem name elevatedUsers then [ "wheel" ] else [ ])
        ++ (if networkmanager.enable or false then [ "networkmanager" ] else [ ])
      else
        [ ];
  }) userConfigs;

  security = {
    sudo = {
      execWheelOnly = true;
      extraRules = [
        {
          users = elevatedUsers;
          commands = [
            {
              command = "ALL";
              options = [
                "SETENV"
                "NOPASSWD"
              ];
            }
          ];
        }
      ];
    };
  };

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
    // (if userConfigs != { } then { inherit users security; } else { })
    // (if allowHomeManager then { inherit home-manager; } else { });
}
