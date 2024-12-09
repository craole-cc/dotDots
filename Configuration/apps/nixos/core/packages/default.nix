{ config, ... }:
{
  imports = [
    ./tty.nix
    ./gui.nix
    ./protocol.nix
  ];
}
