{self, ...}: let
  paths = {
    src = ./.;
    lib = ./Libraries;
    api = ./API;
    repl = ./repl.nix;
  };
  inherit (self.inputs.nixosCore) lib legacyPackages;
  inherit (paths) src;
  inherit (import paths.lib {inherit lib src;}) lix;
  api = import paths.api {inherit lix;};

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
  in {
    inherit (import ./shell.nix {inherit pkgs;}) default;
    # This doesn't  work
    repl = import ./repl_shell.nix {
      inherit pkgs api lix lib system;
      all = self;
    };
  });

  #: This works   fine
  replOld = import ./repl.nix {
    inherit api lix lib pkgs system;
    all = self;
  };
in {
  inherit
    nixosConfigurations
    devShells
    replOld
    ;
}
