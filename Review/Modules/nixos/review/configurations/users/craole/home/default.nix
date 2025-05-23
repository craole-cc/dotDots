{ pkgs, ... }:
{
  imports = [ ];

  programs = {
    bat.enable = true;
    btop.enable = true;
    brave.enable = true;
    helix.enable = true;
    git = {
      enable = true;
      userName = "Craole";
      userEmail = "32288735+Craole@users.noreply.github.com";
    };
    zed-editor.enable = true;

  };
  home = {
    sessionVariables.READER = "bat";
    packages = with pkgs; [
      # hello
      bat
      btop
      coreutils
      curl
      devenv
      diffutils
      dust
      eza
      fastfetch
      fd
      findutils
      fzf
      gawk
      getent
      gh
      gitui
      gnused
      gnused
      helix
      jq
      nerd-fonts.victor-mono
      nil
      nix-index
      nixd
      nixfmt-rfc-style
      onefetch
      ripgrep
      rsync
      sd
      shellcheck
      shfmt
      tldr
      tokei
      trashy
      treefmt
      undollar
      wget
      yazi
      zig
    ];
  };
}
