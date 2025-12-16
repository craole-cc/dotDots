{policies, ...}: let
  app = "starship";
  enable = policies.dev;
in {
  programs.${app} = {
    inherit enable;
  };
  imports = [
    ./settings.nix
    ./shells.nix
  ];
}
