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
    yamlfmt
    stylua
  ];

  shellHook = ''
    eval "$(direnv hook bash)"
    eval "$(zoxide init bash)"
    eval "$(thefuck --alias)"
    eval "$(starship init bash)"
  '';
}
