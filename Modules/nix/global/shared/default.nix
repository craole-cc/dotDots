{
  pkgs,
  lix,
  inputs,
  cfg,
  ...
}: let
  packages = import ./packages.nix {inherit lix pkgs inputs;};
  formatting = import ./fmt.nix {inherit lix pkgs;} // packages;
in
  {inherit pkgs lix inputs cfg;}
  // packages
  // formatting
