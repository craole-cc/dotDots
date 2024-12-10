{
  config,
  lib,
  pkgs,
  ...
}:
let
  #| Native Imports
  inherit (lib.options) mkOption;
  inherit (lib.attrsets) mapAttrs;

  #| Extended Imports
  inherit (config) DOTS;
  base = "hosts";
  mod = DOTS.modules.host;
  src = DOTS.sources.host.configuration.attrs;
in
{
  options.DOTS.${base} = mkOption {
    description = "";
    default = mapAttrs (name: path: mod name path) src;
  };
}
