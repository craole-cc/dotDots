{ config, ... }:
let
  user = "craole";
  autoLogin=true
in
{
  dots = {
    services = {
      gnome.enable = true;
      hyprland.enable = true;
    };
  };

  users = {
    users.${user} = {
      isNormalUser = true;
      description = "Craig Cole";
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
    };
  };

  home-manager = {
    users.${user} =
      { osConfig, ... }:
      {
        home.stateVersion = osConfig.system.stateVersion;
        programs.home-manager.enable = true;
        imports = [
          ./modules
          ./services
          ./programs
        ];
      };
  };

  services.displayManager = {
    autoLogin = {
      inherit (autoLogin) enable;
      inherit user;
    };
  };
}
