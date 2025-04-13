{
  config,
  lib,
  host,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (host) userConfigs;

  # Get allowHomeManager from host config
  allowHomeManager = host.allowHomeManager or false;

  mkUser = username: userConfig: {
    users.users.${username} = {
      inherit (userConfig)
        description
        hashedPassword
        id
        isNormalUser
        ;
      isAdminUser = userConfig.isAdminUser or false;
      extraGroups = [
        "wheel"
        "networkmanager"
        "video"
        "audio"
      ];
    };

    # Configure home-manager only if it's allowed at host level
    home-manager.users.${username} =
      mkIf (allowHomeManager && (userConfig.applications.home-manager.enable or false))
        {
          home = {
            inherit username;
            homeDirectory = "/home/${username}";
            stateVersion = config.system.stateVersion;
          };

          # Set up git if configured
          # programs.git = mkIf (userConfig.applications.git or { } != { }) {
          #   enable = true;
          #   inherit (userConfig.applications.git) name email;
          # };

          # Enable other requested applications
          # programs = lib.mkMerge [
          #   (builtins.mapAttrs (name: cfg: { enable = cfg.enable or false; }) (
          #     removeAttrs userConfig.applications [
          #       "git"
          #       "home-manager"
          #     ]
          #   ))
          #   { }
          # ];
        };
  };
in
{
  # Apply configurations for all users
  config = lib.mkMerge (lib.mapAttrsToList mkUser userConfigs);
}
