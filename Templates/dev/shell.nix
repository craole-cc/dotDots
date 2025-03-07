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
    treefmt2

    #| Image Tools
    viu
    imv
    sxiv

    #| Languages Tools and Formatters
    # coreutils-prefixed
    # php

    #| Nix
    nixfmt-rfc-style
    nixd
    deadnix

    #| JavaScript/TypeScript
    biome # Formatter, linter, and more
    nodePackages_latest.prettier # Formatter
    # nodejs-slim_latest
    prettierd # Formatter daemon
    pnpm

    #| Rust
    rustup
    rustfmt # Formatter
    leptosfmt

    #| Python
    # python314
    ruff

    #| Shell
    shfmt
    shellcheck
    shellharden

    #| SQL
    # sqlfluff # Formatter/linter

    #| Configuration
    taplo # Toml Formatter
    stylua # Lua Formatter
    yamlfmt # YamlFormatter

    # Typst
    typst
    typstfmt # Formatter
    typstyle # Linter

    rustup
    # YAML

    # Go
    asmfmt # Formatter

    # Linting
    actionlint # GitHub Actions
    editorconfig-checker # EditorConfig
    eclint # EditorConfig
    markdownlint-cli2 # Markdown
    tenv # Terraform
    typos # Typo correction

    # Shell
    fish-lsp
    # nufmt # NuShell Formatter

    # Other
    keep-sorted # Sorter
    typst # Typesetting system
  ];
}
