{lix, ...}: let
  registry = import ./registry.nix;

  inputs = import ./inputs.nix {
    inherit lix;
    inherit (registry) sources;
  };

  overlays = import ./overlays.nix {
    inherit lix inputs;
    inherit (registry) overlays;
  };

  modules = import ./modules.nix {
    inherit lix overlays;
    inherit (registry) modules;
  };

  packages = import ./packages.nix {
    inherit lix inputs overlays;
    inherit (registry) packages;
  };
in {inherit inputs modules overlays packages registry;}
