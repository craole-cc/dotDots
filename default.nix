{self, ...}: rec {
  src = ./.;
  all = self;
  args = {inherit api lix all;};

  inherit (self.inputs) nixosCore nixosHome nixosSystems;
  inherit (nixosCore) lib;
  inherit (lib.attrsets) genAttrs attrValues;

  inherit (import ./Libraries {inherit lib src;}) lix;
  api = {inherit (import ./API {inherit lix;}) hosts users;};
  repl = import ./repl.nix args;

  perSystem = genAttrs (import nixosSystems);

  pkgs = perSystem (system:
    lix.getPkgs {
      nixpkgs = nixosCore;
      inherit system;
    });

  # devShells = let
  #   base = ./Packages/custom/dots;
  # in {
  #   default = (import ./shell.nix {inherit pkgs;}).default;
  #   # dots = ./p/dots.nix;
  #   # media = ./p/media.nix;
  # };
      devShells = perSystem (
      system: let
        pkgs = lix.getPkgs {
          nixpkgs = nixosCore;
          inherit system;
        };
      in {default = (import ./shell.nix {inherit pkgs;}).default;}
    );
}
