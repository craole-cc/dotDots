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
    dconf = {
      enable = true;
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
      cachix

      #| Development
      nil
      nixd
      alejandra
      nixfmt-rfc-style
      nix-info
      shellcheck
      shfmt
      helix
      helix-gpt

      #| Filesystem
      dust
      eza
      macchina
      fastfetch
      cpufetch
      neofetch
      ufetch

      #| Utilities
      brightnessctl
      speedtest-go
      fend
      libqalculate
      radio-cli
    ]
    ++ (
      if gui then
        [
          ansel
          brave
          darktable
          dconf2nix
          dconf-editor
          freetube
          inkscape-with-extensions
          kitty
          qbittorrent
          shortwave
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
