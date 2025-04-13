{
  config,
  lib,
  host,
  paths,
  ...
}:
let
  inherit (lib.modules) mkIf mkForce mkMerge;
  inherit (lib.attrsets)
    removeAttrs
    mapAttrsToList
    attrValues
    mapAttrs
    ;
  inherit (lib.lists) any concatLists;
  inherit (host) userConfigs;

  hasNetworking =
    builtins.elem "wired" host.capabilities || builtins.elem "wireless" host.capabilities;
  hasVideo = builtins.elem "video" host.capabilities;
  hasAudio = builtins.elem "audio" host.capabilities;

  isAdmin =
    username: userConfig:
    (userConfig.isAdminUser or false)
    || (any (person: person.name == username && (person.admin or false)) host.people);

  mkGroups =
    username: userConfig:
    (if (isAdmin username userConfig) then [ "wheel" ] else [ ])
    ++ (if hasNetworking then [ "networkmanager" ] else [ ])
    ++ (if hasVideo then [ "video" ] else [ ])
    ++ (if hasAudio then [ "audio" ] else [ ]);

  mkHomePackages =
    userConfig:
    let
      apps = userConfig.applications or { };
      importPackage =
        name: cfg:
        let
          packagePath = "${paths.pkgs.home}/${name}";
        in
        if builtins.pathExists packagePath then
          [
            {
              imports = [ packagePath ];
              config.programs.${name} = mapAttrs (key: value: mkForce value) (
                { enable = cfg.enable; } // (removeAttrs cfg [ "enable" ])
              );
            }
          ]
        else
          [ ];
      mkPackageModule = name: cfg: importPackage name cfg;
    in
    concatLists (attrValues (mapAttrs mkPackageModule (removeAttrs apps [ "home-manager" ])));

  mkUser = username: userConfig: {
    users.users.${username} = {
      inherit (userConfig)
        description
        hashedPassword
        isNormalUser
        ;
      uid = userConfig.id or null;
      extraGroups = mkGroups username userConfig;
    };

    home-manager.users.${username} = mkIf (host.allowHomeManager or false) {
      imports = mkHomePackages userConfig;
      home.stateVersion = config.system.stateVersion;
      programs.home-manager.enable = true;
      wayland.windowManager.hyprland.enable = userConfig.desktop.manager or "" == "hyprland";
    };
  };
in
{
  config = mkMerge (mapAttrsToList mkUser userConfigs);
}
