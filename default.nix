{self, ...}: let
  paths = {
    src = ./.;
    lib = ./Libraries;
    api = ./API;
    repl = ./repl.nix;
  };
  all = self;
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
    pkgs
    system
    ;

  args = {inherit all api lix pkgs;};

  devShells = per (system: {
    inherit (import ./shell.nix {}) default;
  });
  repl = import ./repl.nix args;
in {
  nixosConfigurations = lix.mkCore {
    inherit args;
    inherit (args) api;
    inherit (all) inputs;
  };
  inherit devShells;
  inherit lib lix args repl system pkgs;
}
