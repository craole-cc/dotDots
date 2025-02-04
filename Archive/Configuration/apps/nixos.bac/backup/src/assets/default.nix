{ config, lib, ... }:
let
  #| Internal Imports
  inherit (config.DOTS) Libraries;
  inherit (Libraries.filesystem) pathsIn;
  inherit (Libraries.helpers) mkSource;

  #| External Imports
  inherit (lib.options) mkOption;
  inherit (lib.types) attrs path attrsOf;
in
{
  options.DOTS.Sources.assets = {
    pictures = mkOption { default = mkSource ./pictures; };
    templates = mkOption { default = mkSource ./templates; };
  };
}
