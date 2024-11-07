{ config, lib, ... }:
let
  inherit (lib.options) mkOption;
  inherit (lib.types) attrs;
  inherit (config) DOTS;

  base = "programs";
  mod = "git";
  cfg = DOTS.${base}.${mod};
in
{
  options.DOTS.${base}.${mod} = mkOption {
    description = "{{mod}}";
    default = {
      enable = true;
      lfs.enable = true;
    };
    type = attrs;
  };

  config.${base}.${mod} = cfg;
}
