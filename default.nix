{self ? null, ...}: let
  paths = {
    src = ./.;
    lib = ./Libraries;
    api = ./API;
    repl = ./repl.nix;
  };

  inherit (paths) src;
  inherit (import paths.lib {inherit src;}) lix;
  api = import paths.api {inherit lix;};
  # inherit (builtins) currentSystem;
  inherit (lix) getFlakeOrConfig;

  all =
    if (self != null)
    then self
    else getFlakeOrConfig {path = src;};

  # pkgsFromInputsPath =
  #   if flake != null && flake ? inputs
  #   then let
  #     path = findFirstPath {
  #       inputs = flake.inputs;
  #       names = [
  #         "nixpkgs"
  #         "nixPackages"
  #         "nixpkgsUnstable"
  #         "nixpkgsStable"
  #         "nixpkgs-unstable"
  #         "nixpkgs-stable"
  #         "nixosPackages"
  #         "nixosUnstable"
  #         "nixosStable"
  #       ];
  #     };
  #   in
  #     if path != null
  #     then import path {}
  #     else null
  #   else null;

  systems = {nix-systems ? null}: let
    inherit (lib.lists) unique;
    inherit (lib.attrsets) genAttrs;
    current = builtins.currentSystem;
    defined = lib.mapAttrsToList (name: host: host.system or host.platform or current) api.hosts;
    popular =
      if nix-systems != null
      then import nix-systems
      else [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
    all = unique (defined ++ popular);
    per = genAttrs all;
  in {
    inherit all current defined per popular;
  };
  # inherit (all.inputs) nixosCore nixosSystems;
  nixosCore = all.inputs.nixosCore or lix.pkgs;

  inherit (nixosCore) lib;
  args = {inherit all api lix;};

  repl = import ./repl.nix args;
  # pkgs = (
  #   if builtins ? getFlake
  #   then (getFlake (toString ./.)).inputs.nixosCore.legacyPackages.${currentSystem}
  #   else import <nixpkgs> {}
  # );

  # eachSystem = lib.genAttrs (import all.inputs.nixosSystems);
  # perSystem = eachSystem (system: {
  #   pkgs = lix.getPkgs {
  #     nixpkgs = nixosCore;
  #     inherit system;
  #   };
  # });
  inherit (systems {nix-systems = all.inputs.nixosSystems;}) per;
  devShells = system: {
    inherit (import ./shell.nix {}) default;
  };
in {
  nixosConfigurations = lix.mkCore {
    inherit args;
    inherit (args) api;
    inherit (self) inputs;
  };
  inherit lib lix args repl devShells systems;
}
