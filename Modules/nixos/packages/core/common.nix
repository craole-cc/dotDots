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
    figlet
    fzf
    gawk
    getent
    gh
    gitui
    gnused
    helix
    imagemagick
    lolcat
    nil
    nix-index
    nixfmt-rfc-style
    ripgrep
    rsync
    speedtest-go
    trashy
    treefmt
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
