{ ... }: {
  imports = [
    ../../common
    ../../common/picom.nix
    ./keyboard.nix
    ./mouse.nix
    ./touchpad.nix
  ];
  services.xserver.enable = true;
}