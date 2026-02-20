{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    neovim.url = "github:nix-community/neovim-nightly-overlay";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    neovim,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [
            neovim.overlays.default
          ];
        };
      in {
        devShells.default = pkgs.mkShell {
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
            treefmt

            #| Image Tools
            viu
            imv
            sxiv

            #| Languages Tools and Formatters
            coreutils-prefixed

            #| Nix
            nixfmt-rfc-style
            alejandra
            nixd
            deadnix

            #| JavaScript/TypeScript
            biome # Formatter, linter, and more
            nodePackages_latest.prettier # Formatter
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
          ];
          # inputsFrom = [ (import ./shell.nix { inherit pkgs; }) ];
          shellHook = ''
            fastfetch

            # if [ t1 ]; then
            #   if [ -n "$VISUAL" ] ;then
            #     "$VISUAL"
            #   elif [ -n "$EDITOR" ]; then
            #     nvim
            #   fi
            # fi
          '';
        };
      }
    );
}
