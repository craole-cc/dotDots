{ config, pkgs, ... }:
let
  inherit (config.dots.alpha) name;
in
{
  environment.systemPackages = with pkgs; [
    nixd
    nixfmt-rfc-style
  ];
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
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "24.11";
}
