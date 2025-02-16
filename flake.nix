{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          # pre-commit
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
          lesspipe
          rust-script
          # lmstudio
          # langgraph-cli
          just
          powershell
          bashInteractive

          #| Formatters
          treefmt2
          actionlint
          asmfmt
          alejandra
          shfmt
          yamlfmt
          stylua
          biome
          fish
          keep-sorted
          leptosfmt
          rufo
          sqlfluff
          tex-fmt
          tenv
          toml-sort
          taplo
          typos
          typst
          typstyle
          typstfmt
          markdownlint-cli2
          editorconfig-checker
          eclint
          biome
          nufmt
          editorconfig-checker
        ];

        # shellHook = ''
        #   . /home/craole/.dots/bashrc
        # '';
      };
    });
}
