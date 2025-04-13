{
  config,
  lib,
  host,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (host) userConfigs;

  # Get host capabilities
  hasNetworking =
    builtins.elem "wired" host.capabilities || builtins.elem "wireless" host.capabilities;
  hasVideo = builtins.elem "video" host.capabilities;
  hasAudio = builtins.elem "audio" host.capabilities;

  # Helper function to check if user is admin
  isAdmin =
    username: userConfig:
    (userConfig.isAdminUser or false)
    || (lib.any (person: person.name == username && (person.admin or false)) host.people);

  # Helper function to build group list based on host capabilities
  mkGroups =
    username: userConfig:
    (if (isAdmin username userConfig) then [ "wheel" ] else [ ])
    ++ (if hasNetworking then [ "networkmanager" ] else [ ])
    ++ (if hasVideo then [ "video" ] else [ ])
    ++ (if hasAudio then [ "audio" ] else [ ]);

  # Helper function to build programs configuration
  mkPrograms =
    userConfig:
    let
      apps = removeAttrs (userConfig.applications or { }) [ "home-manager" ];
    in
    builtins.mapAttrs (
      name: cfg:
      {
        enable = cfg.enable or false;
      }
      // (removeAttrs cfg [ "enable" ])
    ) apps;

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
      home = {
        inherit username;
        homeDirectory = "/home/${username}";
        stateVersion = config.system.stateVersion;
      };

      # Desktop-specific configuration
      wayland.windowManager.hyprland.enable = userConfig.desktop.manager or "" == "hyprland";

      # Display manager auto-login
      # services.greetd = mkIf (userConfig.display.autoLogin or false) {
      #   enable = true;
      #   settings.initial_session.user = username;
      # };

      # Programs configuration (including git and other applications)
      programs = mkPrograms userConfig;
    };
  };
in
{
  config = lib.mkMerge (lib.mapAttrsToList mkUser userConfigs);
}
