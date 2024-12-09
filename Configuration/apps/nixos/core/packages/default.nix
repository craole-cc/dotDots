{ config, ... }:
let
  common = ./common.nix;
  protocolSpecific = if config.xserver.enable then ./xserver.nix else ./wayland.nix;
in
{
  imports = [
    common
    protocolSpecific
  ];
}
