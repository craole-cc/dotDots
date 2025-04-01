{
  # imports = [
  #   ./settings.nix
  #   ./keybindings.nix
  #   ./languages.nix
  # ];

  programs.helix = {
    enable = true;
    settings = import ./settings.nix;
    languages = import ./languages.nix;
  };
}
