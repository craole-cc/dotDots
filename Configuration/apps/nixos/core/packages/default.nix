{ config, ... }:
{
  imports = [
    ./common.nix
    ./xserver.nix
    # ./wayland.nix
  ];
}
