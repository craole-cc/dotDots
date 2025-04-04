{
  config,
  lib,
  ...
}:
let
  inherit (lib.options) mkOption;

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
      default = makeSource ../export/context;
    };
    base = mkOption {
      description = "{{mod}} base {{base}}";
      default = makeSource ../export/base;
    };
  };
}
