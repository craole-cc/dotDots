{
  config,
  lib,
  ...
}:
let
  inherit (lib.options) mkEnableOption;

  base = "programs";
in
{
  options.${base} = {
    enable = mkEnableOption mod // {
      default = true;
    };
    silent = mkEnableOption mod // {
      default = true;
    };
  };

  config.${base}.${mod} = cfg;
}
