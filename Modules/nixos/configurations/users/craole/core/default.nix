{
  programs = {
    direnv = {
      enable = true;
      silent = true;
    };
    git.enable = true;
    nix-ld.enable = true;
    starship.enable = true;
    vivid.enable = true;
    yazi.enable = true;
  };

  services = {
    atuin.enable = true;
    tailscale.enable = true;
  };
}
