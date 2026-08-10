{
  config,
  host,
  lib,
  top,
  lix,
  ...
}: let
  dom = "system";
  mod = "clean";
  cfg = config.${top}.inputs.${dom}.${mod};
  nixCfg = config.${top}.inputs.${dom}.nix;

  inherit (lib.modules) mkIf;
  inherit (lib.options) literalExpression mkEnableOption mkOption;
  inherit (lib.types) nullOr str;
  payload = {
    programs.nh = {
      enable = true;
      clean = {
        enable = true;
        extraArgs = "--keep-since ${cfg.keepSince} --keep ${cfg.keepCount}";
      };
      inherit (cfg) flake;
    };
  };
  inherit (lix.modules.core._) mkStaged;
in {
  options.${top}.inputs.${dom}.${mod} = {
    enable =
      mkEnableOption mod
      // {
        default = true;
      };
    keepSince = mkOption {
      description = "Delete generations older than";
      default = "3d";
      defaultText = literalExpression ''"3d"'';
      type = str;
    };
    keepCount = mkOption {
      description = "Number of generations to keep";
      default = "5";
      defaultText = literalExpression ''"5"'';
      type = str;
    };
    flake = mkOption {
      description = "Flake path for nh";
      default = host.paths.dots or null;
      defaultText = literalExpression "host.paths.dots or null";
      type = nullOr str;
    };
  };

  config = lib.mkMerge (mkStaged {
    inherit top payload;
    condition = (cfg.enable && !(nixCfg.enable or false));
  });
}
