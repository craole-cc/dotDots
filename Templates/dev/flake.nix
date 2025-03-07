{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    neovim.url = "github:nix-community/neovim-nightly-overlay";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      neovim,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [
            neovim.overlays.default
          ];
        };
      in
      {
        devShells.default = pkgs.mkShell {
          inputsFrom = [ (import ./shell.nix { inherit pkgs; }) ];
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
