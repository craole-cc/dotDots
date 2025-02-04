{
  imports = [
    ./bindings.nix
    ./config.nix
    ./profiles.nix
    ./scripts.nix
  ];
  programs.mpv = {
    enable = true;
  };
}
