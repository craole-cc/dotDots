{
  lib,
  host,
  config,
  pkgs,
  ...
}: let
  inherit (lib.lists) elem;

  isX11 = config.services.xserver.enable;
  # isGUI = enabled {
  #   # verbose = true;
  #   checks = [
  #     {path = desktopManager;}
  #     {
  #       path = displayManager;
  #       keys = ["gdm" "cosmic-greeter" "lemurs" "ly" "sddm"];
  #     }
  #     {
  #       path = xserver.displayManager;
  #       keys = ["gdm" "sddm" "lightdm" "startx"];
  #     }
  #   ];
  # };
in {
  imports = [./git.nix];

  programs = {
    starship.enable = true;
    obs-studio.enableVirtualCamera = elem "conferencing" host.capabilities;
  };

  environment.systemPackages = with pkgs;
    [
      #| Nix
      alejandra
      direnv
      nil
      nix-index
      nix-info
      nix-prefetch
      nix-prefetch-docker
      nix-prefetch-github
      nix-prefetch-scripts
      nixd
      # nixfmt
      nixfmt-rfc-style

      #| Dev
      dust
      fd
      fend
      fzf
      gcc
      jq
      lsd
      ripgrep
      rsync
      rust-script
      rustfmt
      shellcheck
      shfmt
      speedtest-go
      taplo
      trashy
      treefmt
      usbutils
      uutils-coreutils-noprefix
    ]
    ++ (
      if isX11
      then [xclip xsel]
      else [wl-clipboard]
    );
}
# sessionVariables = {
#   EDITOR = "hx";
#   VISUAL = "code --wait  --reuse-window";
# };
