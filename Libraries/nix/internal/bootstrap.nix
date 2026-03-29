{
  lib,
  path,
}: let
  inherit (builtins) getFlake pathExists;
  hasFlake = pathExists (toString path + "/flake.nix");
  rawFlake =
    if hasFlake
    then getFlake (toString path)
    else {};
in
  if lib != null
  then lib
  else if rawFlake ? inputs && rawFlake.inputs ? nixpkgs
  then rawFlake.inputs.nixpkgs.lib
  else import <nixpkgs/lib>
