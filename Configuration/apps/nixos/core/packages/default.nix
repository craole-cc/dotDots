{
  imports = [
    ./common.nix
    ./xserver.nix
    # ./wayland.nix
  ];

  specialArgs.pop = "lol";
}
