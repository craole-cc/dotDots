{
  pkgs,
  inputs,
  ...
}: let
  treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs (
    import ../treefmt.nix {inherit inputs;}
  );
in
  treefmtEval.config.build.check pkgs
