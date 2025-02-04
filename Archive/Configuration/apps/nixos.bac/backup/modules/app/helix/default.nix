{
  imports = [
    ./settings.nix
    ./keybindings.nix
    ./languages.nix
  ];

  programs.helix = {
    enable = true;
    defaultEditor = true;
  };
}
