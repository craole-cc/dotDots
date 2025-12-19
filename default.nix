{self, ...}: let
  paths = {
    src = ./.;
    lib = ./Libraries;
    api = ./API;
    cli = ./Packages/cli;
  };
  inherit (self.inputs.nixosCore) lib legacyPackages;
  inherit (paths) src;
  inherit (import paths.lib {inherit lib src;}) lix;
  api = import paths.api {inherit lix;};
  all = self;

  inherit
    (lix.getSystems {
      inherit (api) hosts;
      inherit legacyPackages;
    })
    per
    pkgsFor
    pkgs
    system
    ;

  nixosConfigurations = lix.mkCore {
    inherit (api) hosts users;
    inherit (lib) nixosSystem;
    args = {
      flake = self;
      inherit lix;
    };
  };

  devShells = per (system: let
    pkgs = pkgsFor system;
    dots = import (paths.cli + "/dots") {
      inherit all pkgs lib api lix system;
    };
  in {default = dots;});

  #TODO: This should somehow be moved into devShells.dots, but how?
  repl = import (paths.cli + "/dots/repl.nix") {
    inherit all pkgs lib api lix system;
  };
in {
  inherit
    nixosConfigurations
    devShells
    repl
    ;
}
