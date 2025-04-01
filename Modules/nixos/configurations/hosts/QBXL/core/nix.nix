{ config, pkgs, ... }:
let
  inherit (config.dots.alpha) name;
in
{
  networking = {
    hostId = with builtins; substring 0 8 (hashString "md5" config.networking.hostName);
  };
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
  environment.systemPackages = with pkgs; [
    nixd
    nixfmt-rfc-style
  ];
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "24.11";
  wsl = {
    enable = true;
    defaultUser = name;
  };
}
