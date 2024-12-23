{ config, pkgs, ... }:
let
  inherit (config.services) pipewire;
  gui =
    with config;
    services.xserver.enable || programs.hyprland.enable || services.displayManager.sddm.wayland.enable;
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
      helix

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
      if gui then
        [
          ansel
          brave
          darktable
          freetube
          inkscape-with-extensions
          kitty
          qbittorrent
          via
          vscode-fhs
          warp-terminal
          whatsapp-for-linux
        ]
      else
        [ ]
    )
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
