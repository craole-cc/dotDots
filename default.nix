{self, ...}: let
  src = ./.;
  all = self;
  args = {inherit api lix all;};

  inherit (self.inputs) nixosCore nixosHome nixosSystems;
  inherit (nixosCore) lib;
  inherit (lib.attrsets) genAttrs attrValues;

  inherit (import ./Libraries {inherit lib src;}) lix;
  api = {inherit (import ./API {inherit lix;}) hosts users;};
  repl = import ./repl.nix args;

  eachSystem = genAttrs (import nixosSystems);
  perSystem = eachSystem (system: {
    pkgs = lix.getPkgs {
      nixpkgs = nixosCore;
      inherit system;
    };
  });
  devShells = eachSystem (system: {
    inherit (import ./shell.nix {inherit (perSystem.${system}) pkgs;}) default;
  });
  # devShells = let
  #   base = ./Packages/custom/dots;
  # in {
  #   default = (import ./shell.nix {inherit pkgs;}).default;
  #   # dots = ./p/dots.nix;
  #   # media = ./p/media.nix;
  # };
  # devShells = eachSystem (
  #   system: let
  #     pkgs = lix.getPkgs {
  #       nixpkgs = nixosCore;
  #       inherit system;
  #     };
  #   in {
  #     default = (import ./shell.nix {inherit pkgs;}).default;
  #   }
  # );
in {
  inherit args repl devShells;
}
