{
  lix,
  flakeInputs ? lix.flake.inputs or {},
  ...
}: let
  inputs = import ./inputs.nix {
    inherit lix;
    inputs = flakeInputs;
  };
  overlays = import ./overlays.nix {inherit inputs;};
  modules = import ./modules.nix {inherit lix inputs;};
in {inherit inputs modules overlays;}
