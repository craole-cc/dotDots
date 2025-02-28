{
  lib,
  config,
  ...
}:
let
  base = "interface";
  mod = "programs";
  cfg = config.DOTS.${base}.${mod};

  inherit (lib.options) mkOption;
  inherit (lib.types)
    attrs
    ;
in
{
  options.DOTS.${base}.${mod} = mkOption {
    description = "List of {{base}}-specific programs";
    default = {
      git = {
        enable = true;
        lfs.enable = true;
      };
      direnv = {
        enable = true;
        silent = true;
      };
      # seahorse.enable = true;
    };
    type = attrs;
  };

  config.${mod} = cfg;
}
