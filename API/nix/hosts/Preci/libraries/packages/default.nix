{lix, ...}: let
  registry = import ./registry.nix;

  sources = import ./sources.nix {
    inherit lix;
    inherit (registry) sources;
  };

  overlays = import ./overlays.nix {
    inherit lix sources;
    inherit (registry) overlays;
  };

  modules = import ./modules.nix {
    inherit lix overlays;
    inherit (registry) modules;
  };

  packages = import ./packages.nix {
    inherit lix sources;
    inherit (registry) pools;
  };
in {
  inherit modules overlays packages registry;
  inputs = sources;
}
