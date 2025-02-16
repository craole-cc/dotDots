{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages.default = pkgs.writeScriptBin "dots-env" ''
        echo "This is a development environment flake"
      '';

      devShells.default = pkgs.mkShell {
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
          lesspipe
          rust-script
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

        shellHook = ''
          #@ Show the system info
          fastfetch

          #@ Open the DOTS directory in the editor
          if [ -n "$DISPLAY" ]; then
            "$VISUAL" "$DOTS"
          else
            "$EDITOR" "$DOTS"
          fi
        '';
      };
    });
}
