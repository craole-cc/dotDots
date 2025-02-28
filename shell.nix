{
  pkgs ? import <nixpkgs> { config.allowUnfree = true; },
}:
pkgs.mkShell {
  buildInputs = with pkgs; [
    vscodium-fhs
    getoptions
    pre-commit
    eza
    bat
    fd
    btop
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
    lesspipe
    rust-script
    # lmstudio
    # langgraph-cli
    just
    powershell
    bashInteractive
    glib

    #| Languages
    python314
    rustup
    coreutils-prefixed
    ruby
    php
    nodejs-slim_latest
    pnpm

    #| Image Tools
    viu
    imv
    sxiv

    #| Formatters
    treefmt2
    actionlint # ? GitHub Actions
    asmfmt # ? Go
    alejandra # ? Nix
    shfmt # ? Shell
    yamlfmt # ? YAML
    stylua # ? Lua
    biome # ? javascript and typescript
    fish # ? fish and fish_indent
    keep-sorted # ? Sorter
    leptosfmt # ? leptos rs
    rufo # ? Ruby
    sqlfluff # ? SQL
    tex-fmt # ? TeX
    tenv # ? Terraform
    toml-sort # ? TOML
    taplo # ? TOML
    typos # ? Typo correction
    typst # ? typesetting system to replace LaTeX
    typstyle # ? typst style
    typstfmt # ? typst formatter
    markdownlint-cli2 # ? Markdown
    editorconfig-checker # ? EditorConfig
    eclint # ? EditorConfig linter written in Go
    biome # ? Json, JavaScript and TypeScript
    nufmt
    editorconfig-checker
  ];

  shellHook = ''
    #@ Show the system info
    # fastfetch
    # ede
  '';
}
