{ config, lib, ... }:
let
  inherit (lib.options) mkOption;
  inherit (lib.types) attrs;

  #| Extended Imports
  inherit (config) DOTS;
  base = "sources";
  mod = "host";

  inherit (DOTS.lib.helpers) makeSource;
in
{
  options.DOTS.${base}.${mod} = {
    configuration = mkOption {
      description = "{{mod}} configuration {{base}}";
      default = makeSource ../configurations;
    };
    context = mkOption {
      description = "{{mod}} context {{base}}";
      default = makeSource ../components/context;
    };
    machine = mkOption {
      description = "{{mod}} machine {{base}}";
      default = makeSource ../components/base;
    };
  };
}
