{self, ...}: let
  all = self;
  src = ./.;
  inherit (import ./Libraries {inherit lib src;}) lix lib;
  api = import ./API {inherit lix;};

  inherit
    (lix.getSystems {
      inherit (api) hosts;
      inherit (self.inputs.nixosCore) legacyPackages;
    })
    per
    pkgsFor
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
    default = import ./Packages/cli/dots {
      inherit all pkgs lib api lix system;
    };
  });
in {
  inherit
    nixosConfigurations
    devShells
    ;
}
