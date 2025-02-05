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

    #| Formatters
    treefmt2
    actionlint # ? GitHub Actions
    asmfmt # ? Go
    shfmt # ? Shell
    yamlfmt # ? YAML
    stylua # ? Lua
    deno # ? javascript and typescript
    beautysh # ? bash
    biome # ? javascript and typescript
    fish # ? fish and fish_indent
    keep-sorted # ? Sorter
    leptosfmt # ? leptos rs
    sqlfluff # ? SQL
    tex-fmt # ? TeX
    tenv # ? Terraform
    toml-sort # ? TOML
    taplo # ? TOML
    typos # ? Typo correction
    typst # ? typesetting system
  ];

  shellHook = ''
    eval "$(direnv hook bash)"
    eval "$(zoxide init bash)"
    eval "$(thefuck --alias)"
    eval "$(starship init bash)"
  '';
}
