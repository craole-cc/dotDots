{
  pkgs,
  inputs,
  ...
}: let
  treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs (import ../treefmt.nix);
in
  treefmtEval.config.build.check ../..
