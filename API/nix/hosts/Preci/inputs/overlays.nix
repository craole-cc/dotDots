{
  lix,
  inputs ? lix.flake.inputs or {},
  sources ? import ./sources.nix {inherit lix inputs;},
  ...
}: {inherit (sources) rust-overlay;}
