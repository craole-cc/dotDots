{ config, ... }:
let
  user = "craole";
in
{
  imports = [
    <home-manager/nixos>
    ./environment/gnome
    ./environment/hyprland
    # (import ./environment/hyprland { inherit user; })
  ];

  users.users.${user} = {
    isNormalUser = true;
    description = "Craig Cole";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };

  home-manager = {
    backupFileExtension = "BaC";
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${user} =
      { osConfig, ... }:
      {
        imports = [
          ./services
          ./programs
          ./modules
        ];
        home.stateVersion = osConfig.system.stateVersion;
        programs.home-manager.enable = true;
      };
  };

  services.displayManager = {
    autoLogin = {
      enable = true;
      inherit user;
    };
  };
}
