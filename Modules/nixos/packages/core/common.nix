{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    bat
    btop
    coreutils
    gnused
    curl
    lsd
    dust
    fastfetch
    fd
    findutils
    fzf
    gawk
    getent
    gh
    gitui
    gnused
    helix
    nil
    nix-index
    nixfmt-rfc-style
    ripgrep
    rsync
    trashy
    wget
  ];

  programs = {
    direnv = {
      enable = true;
      silent = true;
    };
    git.enable = true;
    nix-ld.enable = true;
  };
}
