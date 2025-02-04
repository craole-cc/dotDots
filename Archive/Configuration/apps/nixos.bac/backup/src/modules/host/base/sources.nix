{ config, lib, ... }:
let
  #| Top-level Imports
  # inherit (pkgs) lib;
  inherit (config.DOTS) Libraries;

  #| Internal Imports
  inherit (Libraries.helpers) mkSource;

  #| External Imports
  inherit (lib.options) mkOption;
in
{

  options.DOTS.Sources.host = {
    configuration = mkOption { default = mkSource ../configurations; };
    machine = mkOption { default = mkSource ../components/base; };
    context = mkOption { default = mkSource ../components/context; };
  };
}
