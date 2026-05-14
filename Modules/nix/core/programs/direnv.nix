{
  config,
  lix,
  top,
  ...
}:
let
  dom = "programs";
  mod = "direnv";
  cfg = config.${top}.${dom}.${mod};
  inherit (lix.options.construction) mkOption mkTrue mkType;
  inherit (lix.modules.construction) mkIf;
in
{
  options.${top}.${dom}.${mod} = {
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

  config = mkIf cfg.enable {
    programs.${mod} = {
      inherit (cfg) enable silent;
      settings.global = {
        log_format = cfg.format;
        log_filter = cfg.filter;
        load_dotenv = cfg.dotenv;
      };
    };
  };
}
