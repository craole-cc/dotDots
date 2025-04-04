{ pkgs, ... }:
{
  programs = {
    direnv = {
      enable = true;
      silent = true;
    };
    git.enable = true;
    nix-ld.enable = true;
  };

  environment.systemPackages = with pkgs; [
    bat
    btop
    busybox
    coreutils
    curl
    dust
    fastfetch
    fd
    figlet
    findutils
    fzf
    gawk
    getent
    gh
    gitui
    gnused
    gnused
    helix
    imagemagick
    lolcat
    lsd
    nil
    nix-index
    nix-info
    nix-prefetch
    nix-prefetch-docker
    nix-prefetch-github
    nix-prefetch-scripts
    nixfmt-rfc-style
    ripgrep
    fend
    rsync
    speedtest-go
    trashy
    treefmt
    usbutils
    uutils-coreutils-noprefix
    wget
  ];
}
