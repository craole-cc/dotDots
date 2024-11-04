{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.strings) substring;
  inherit (lib.types)
    attrs
    path
    nullOr
    str
    either
    ;
  inherit (config.dot.sources) user home-manager;
  inherit (config.dot.libraries.filesystem)
    listPaths
    mkSource
    nullOrPathOf
    githubPathOf
    ;
  inherit (config.dot.modules.host.current) stateVersion;

  #| Extended Imports
  inherit (config) DOTS;
  base = "sources";
  mod = "user";

  inherit (DOTS.lib.filesystem) mkSource;
in
{
  options.dot.${base}.${mod} = {
    configuration = mkOption { default = mkSource ../configurations; };
    context = mkOption { default = mkSource ../components/context; };
  };
}
