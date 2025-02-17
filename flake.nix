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
        # devShells.default = import ./shell.nix {inherit pkgs;};
        devShells.default = pkgs.mkShell {
          inputsFrom = [(import ./shell.nix {inherit pkgs;})];

          shellHook = ''
            # Original shell.nix shellHook
            fastfetch
            ede

            echo "Development environment loaded!"
            echo "Neovim nightly is available as 'nvim'"
          '';
        };
      }
    );
}
