{ config, ... }:
let
  protocolSpecific = if config.xserver.enable then ./xserver.nix else ./wayland.nix;
in
{
  imports = [
    ./tty.nix
    ./gui.nix
    protocolSpecific
  ];
}
