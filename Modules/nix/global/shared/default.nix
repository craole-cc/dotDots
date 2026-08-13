{
  pkgs,
  lix,
  inputs,
  ...
}: let
  cfg = {
    name = "dotDots";
    version = "2.0.0";
    cache = ".cache";
    prefix = ".";
    allowAI = true;
  };

  packages = import ./packages.nix {inherit lix pkgs inputs;};
  formatting = import ./fmt.nix {inherit lix pkgs;} // packages;
in
  cfg
  // packages
  // formatting
