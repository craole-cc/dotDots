{
  # imports = [
  #   ./settings.nix
  #   ./keybindings.nix
  #   ./languages.nix
  # ];

  programs.helix = {
    enable = true;
    settings = {
      editor = import ./editor.nix;
      keys = import ./keybindings.nix;
    };
    languages = import ./languages.nix;
  };
}
