{ config, ... }:
let
  inherit (config.dots.alpha) name;
in
{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "@wheel"
      name
    ];
  };
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "24.11";
  wsl = {
    enable = true;
    defaultUser = name;
  };
}
