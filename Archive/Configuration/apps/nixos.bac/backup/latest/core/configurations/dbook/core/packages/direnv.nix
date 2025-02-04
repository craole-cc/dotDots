{ config, lib, ... }:
let
  inherit (lib.options) mkEnableOption;
  inherit (config) DOTS;

  base = "programs";
  mod = "direnv";
  cfg = DOTS.${base}.${mod};
in
{
  options.DOTS.${base}.${mod} = {
    enable = mkEnableOption mod // {
      default = true;
    };
    silent = mkEnableOption mod // {
      default = true;
    };
  };

  config.${base}.${mod} = cfg;
}
