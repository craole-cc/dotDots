{ ... }:

{
  programs.home-manager.enable = true;

  imports = [
    ./direnv.nix
    ./git.nix
  ];
}
