{ config, pkgs, ... }:

{
  imports = [
    ./browser.nix
    ./communication.nix
    ./download.nix
    ./remote.nix
  ];
}
