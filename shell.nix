{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  buildInputs = with pkgs; [
    eza
    bat
    fd
    ripgrep
    fzf
    lsd
    delta
    yazi
    tlrc
    tokei
    thefuck
    zoxide
    tldr
    neovim
    helix
    direnv
    nixfmt-rfc-style
    nixd
    statix
    fend
  ];

  shellHook = ''
    DOTS="$HOME/.dots"
    DOTS_BIN="$DOTS/Bin"
    export DOTS DOTS_BIN

    pathman="$DOTS_BIN/utility/files/pathman"
    . "$pathman" --append "$DOTS_BIN"

  '';
}
