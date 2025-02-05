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
    fend
    fastfetch
    treefmt2
  ];

  shellHook = ''
    . /home/craole/.dots/Configuration/bash/config.bash
    DOTS="$HOME/.dots"
    DOTS_BIN="$DOTS/Bin"
    DOTS_CFG="$DOTS/Configuration"
    export DOTS DOTS_BIN DOTS_CFG

    FASTFETCH_CONFIG="$DOTS_CFG/fastfetch/config.jsonc"
    STARSHIP_CONFIG="$DOTS_CFG/starship/config.toml"
    TREEFMT_CONFIG="$DOTS_CFG/treefmt/config.toml"

    . "$DOTS_BIN/utility/files/pathman" --append "$DOTS_BIN"
    fastfetch --config "$FASTFETCH_CONFIG"

    eval "$(direnv hook bash)"
    eval "$(zoxide init bash)"
    eval "$(thefuck --alias)"
    eval "$(starship init bash)"
  '';
}
