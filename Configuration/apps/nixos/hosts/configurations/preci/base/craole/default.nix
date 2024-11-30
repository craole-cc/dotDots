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

  home-manager.users.${mod}.imports = [
    ./programs
    ./packages.nix
    ./fonts.nix
    ./environment.nix
  ];
}
