{ config }:
let
  stateVersion = config.system.stateVersion;
in
{
  users.users.craole = {
    isNormalUser = true;
    description = "Craig 'Craole' Cole";
    extraGroups = [
      "networkmanager"
      "wheel"
      "storage"
    ];
  };

  home-manager.users.craole = {
    home = {
      inherit stateVersion;
    };
  };

}
