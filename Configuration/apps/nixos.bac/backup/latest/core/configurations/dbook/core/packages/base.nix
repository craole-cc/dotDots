{ config, lib, ... }:
let
  inherit (lib.options) mkEnableOption;
  inherit (config) DOTS;

  base = "programs";
in
{
  options.${base}= {
    enable = mkEnableOption mod // {
      default = true;
    };
    silent = mkEnableOption mod // {
      default = true;
    };
  };

  config.${base}.${mod} = cfg;
}
