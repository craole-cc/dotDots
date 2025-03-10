{
  config,
  lib,
  ...
}: let
  cfg = config.dots.users.craole;
in {
  config = lib.mkIf cfg.enable {
    users.users.${cfg.name} = {
      isNormalUser = true;
      description = cfg.fullName;
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
    };

    # dots.services = {
    #   # gnome.enable = cfg.gnome.enable;
    #   # hyprland.enable = cfg.hyprland.enable;
    #   # plasma.enable = cfg.plasma.enable;
    #   # xfce.enable = cfg.xfce.enable;
    # };

    services.displayManager.autoLogin = {
      enable = cfg.autoLogin;
      user = cfg.name;
    };

    home-manager = {
      inherit (cfg) backupFileExtension;
      users.${cfg.name} = {osConfig, ...}: {
        home.stateVersion = osConfig.system.stateVersion;
        programs.home-manager.enable = true;
        dots = {
          # services.hyprland.enable = cfg.hyprland.enable;
        };
        imports = [
          #| Common
          ../../services
          # ../../modules
          # ../../programs

          #| Custom
          ./services
          ./modules
          ./programs
        ];
      };
    };
  };
}
