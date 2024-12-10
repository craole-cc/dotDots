{ config, pkgs, ... }:
let
  inherit (config.services) pipewire;
in
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
  environment.systemPackages =
    with pkgs;
    [
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
      alejandra
      nixfmt-rfc-style
      nix-info
      shellcheck
      shfmt

      #| Filesystem
      dust
      eza

      #| Utilities
      brightnessctl
      speedtest-go
      fend
      libqalculate
    ]
    ++ (
      if pipewire.enable then
        [
          pavucontrol
          easyeffects
        ]
      else
        [ ]
    )
    ++ (if pipewire.jack.enable then [ qjackctl ] else [ ]);
}
