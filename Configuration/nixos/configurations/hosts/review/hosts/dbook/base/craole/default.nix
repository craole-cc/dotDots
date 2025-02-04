let
  mod = "craole";
in
{
  users.users.${mod} = {
    isNormalUser = true;
    description = "Craole";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };
  home-manager.users.${mod} = {
    programs.home-manager.enable = true;

    imports = [
      ./apps.nix
      ./environment.nix
      ./fonts.nix
      # ./plasma.nix
    ];
  };
}
