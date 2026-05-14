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
  path = paths.flake;
  name = baseNameOf path;
  cargo = let
    toml = path + "/Cargo.toml";
  in
    optionalAttrs (pathExists toml) ((fromTOML (readFile toml)) // {path = toml;});
  project =
    {
      inherit path name;
    }
    // cargo;
in {
  inherit project;
}
