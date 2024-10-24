{ config, pkgs, ... }:

{
  imports = [
    ./calculator.nix
    ./productivity.nix
    ./multimedia.nix
    ./terminal.nix
  ];
}
