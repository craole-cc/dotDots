{
  config,
  host,
  lib,
  top,
  ...
}: let
  dom = "system";
  mod = "clean";
  cfg = config.${top}.${dom}.${mod};

  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) nullOr str;
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption mod // {default = true;};
    keepSince = mkOption {
      description = "Delete generations older than";
      default = "3d";
      type = str;
    };
    keepCount = mkOption {
      description = "Number of generations to keep";
      default = "5";
      type = str;
    };
    flake = mkOption {
      description = "Flake path for nh";
      default = host.paths.dots or null;
      type = nullOr str;
    };
  };

  config = mkIf cfg.enable {
    programs.nh = {
      enable = true;
      clean = {
        enable = true;
        extraArgs = "--keep-since ${cfg.keepSince} --keep ${cfg.keepCount}";
      };
      flake = cfg.flake;
    };
  };
}
