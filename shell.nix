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

    #| Image Tools
    viu
    imv
    sxiv

    #| Languages Tools and Formatters
    # python314
    # coreutils-prefixed
    # ruby
    # php
    # nodejs-slim_latest
    pnpm
    treefmt2

    #| Formatters
    # Nix
    alejandra # Formatter

    # JavaScript/TypeScript
    biome # Formatter, linter, and more
    nodePackages_latest.prettier # Formatter
    prettierd # Formatter daemon

    # Rust
    rustfmt # Formatter
    leptosfmt # Formatter

    # Ruby
    ruff

    # Shell
    shfmt # Formatter

    # SQL
    sqlfluff # Formatter/linter

    # Lua
    stylua # Formatter

    # TOML
    taplo # Formatter
    toml-sort # Sorter

    # TeX
    tex-fmt # Formatter

    # Typst
    typstfmt # Formatter

    rustup
    # YAML
    yamlfmt # Formatter

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

  shellHook = ''
    #@ Show the system info
    # fastfetch
    # ede
  '';
}
