{ pkgs, ... }:
{
  programs = {
    git = {
      enable = true;
      lfs.enable = true;
    };
    direnv = {
      enable = true;
      silent = true;
    };
  };
  environment.systemPackages = with pkgs; [
    #| Core Utilities
    usbutils
    uutils-coreutils-noprefix
    busybox
    bat
    fzf
    ripgrep
    sd
    tldr
    fd
    jq
    nix-prefetch-scripts
    nix-prefetch
    nix-prefetch-github
    nix-prefetch-docker

    #| Development
    nil
    nixd
    nixfmt-rfc-style
    nix-info
    shellcheck
    shfmt

    #| Filesystem
    dust
    eza

    #| System
    easyeffects
    pavucontrol
    qjackctl
    brightnessctl

    #| Utilities
    speedtest-go
    fend
    libqalculate
  ];
}
