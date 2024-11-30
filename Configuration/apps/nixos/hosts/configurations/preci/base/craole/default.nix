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
  home-manager.users.${mod}.modules = [
    ./apps.nix
    ./environment.nix
    ./fonts.nix
    ./plasma.nix
  ];
}