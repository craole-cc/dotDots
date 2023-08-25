{...}: {
  # let HM manage itself when in standalone mode
  programs = {
    # direnv.enable = true;
    # direnv.nix-direnv.enable = true;
    # optional for nix flakes support in home-manager 21.11, not required in home-manager unstable or 23.05
    # direnv.nix-direnv.enableFlakes = true;
    bash.enable = true;
    zsh.enable = true;
    light.enable = true;
  };
}
