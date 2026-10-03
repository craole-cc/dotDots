{
  inputs ? lix.inputs or null,
  lix,
  ...
}: let
  registry = import ./registry.nix;

  sources = import ./sources.nix {
    inherit lix inputs;
    inherit (registry) sources;
  };

  overlays = import ./overlays.nix {
    inherit lix sources;
    inherit (registry) overlays;
  };

  modules = import ./modules.nix {
    inherit lix inputs sources overlays;
    inherit (registry) modules;
  };

  packages = import ./packages.nix {
    inherit lix modules;
  };
in {
  inherit modules overlays packages;
  inputs = sources;
}
