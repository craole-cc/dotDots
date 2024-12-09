{ config, ... }:
{
  imports = [
    ./programs.nix
    ./system.nix
  ] ++ (if config.xserver.enable then [ ./xserver.nix ] else [ ./wayland.nix ]);

}
