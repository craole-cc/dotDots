{
  config,
  lix,
  lib,
  top,
  ...
}: let
  dom = "programs";
  mod = "direnv";
  cfg = config.${top}.resolved.${dom}.${mod};
  inherit (lix.options.construction) mkOption mkTrue mkType;
  inherit (lix.modules.construction) mkIf;
  payload = {
    programs.${mod} = {
      inherit (cfg) enable silent;
      settings.global = {
        log_format = cfg.format;
        log_filter = cfg.filter;
        load_dotenv = cfg.dotenv;
      };
    };
  };
  inherit (lix.modules.core.staging) mkStaged;
in {
  options.${top}.resolved.${dom}.${mod} = {
    enable = mkTrue mod;
    silent = mkTrue "silent mode";
    dotenv = mkTrue "load .env files";
    format = mkOption {
      description = "log format string";
      default = "-";
      type = mkType "str";
    };
    filter = mkOption {
      description = "log filter regex";
      default = "^$";
      type = mkType "str";
    };
  };

  config = lib.mkMerge (mkStaged {
    inherit top payload;
    condition = cfg.enable;
  });
}
