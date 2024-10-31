{ config, lib, ... }:
let

  inherit (lib) mkOption;
  inherit (lib.types) attrs path;
  inherit (config) dot;
  inherit (dot.libraries.filesystem) listPaths;

  mkSource =
    name:
    let
      home = ../. + "/${name}";
      inherit ((listPaths home).nix) attrs list;
    in
    {
      inherit home attrs;
      inherit (list) names paths;
    };
in
{
  options.dot.sources.host = {
    configuration = mkOption { default = mkSource "configurations"; };
    machine = mkOption { default = mkSource "components/base"; };
    context = mkOption { default = mkSource "components/context"; };
  };
}
