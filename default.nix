{self, ...}: let
  paths = {
    src = ./.;
    lib = ./Libraries;
    api = ./API;
    repl = ./repl.nix;
  };
  inherit (self) inputs;
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
    # mkShell = pkgs.inputs.developmentShell;

    shell = import ./Packages/custom/dots {
      inherit pkgs lib api lix system;
      all = self;
    };
    # inherit (import ./shell.nix {inherit pkgs;}) default;
  in {
    default = shell;
    # dots = import ./Packages/custom/dots {inherit pkgs mkShell;};
  });

  repl = import ./Packages/custom/dots/tmp_repl.nix {
    inherit api lix lib pkgs system;
    all = self;
  };
in {
  inherit
    nixosConfigurations
    devShells
    repl
    ;
}
