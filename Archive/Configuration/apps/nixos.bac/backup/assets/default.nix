{ config, lib, ... }:
let
  inherit (lib.options) mkOption;
  inherit (lib.types) attrs path attrsOf;
  inherit (config.dot.libraries.filesystem) listPaths mkSource;
in
{
  options.dot.sources.assets = {
    pictures = mkOption {
      default = {
        home = ./pictures;
      };
      type = attrsOf path;
    };
    templates = mkOption { default = mkSource ./templates; };
  };
}
