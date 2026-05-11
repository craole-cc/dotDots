{
  lib,
  paths,
  ...
}: let
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.trivial) fromTOML readFile pathExists;

  #╔═══════════════════════════════════════════════════════════╗
  #║ Project                                                   ║
  #╚═══════════════════════════════════════════════════════════╝
  root = paths.flake;
  name = baseNameOf root;
  cargo = let
    cargoToml = root + "/Cargo.toml";
    cargoExists = pathExists cargoToml;
  in
    optionalAttrs cargoExists (fromTOML (readFile cargoToml));
  project = {inherit root name;} // cargo;
in {inherit project;}
