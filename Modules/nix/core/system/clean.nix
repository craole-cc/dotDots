{
  config,
  host,
  lix,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "system";
    mod = "clean";
  };
  inherit (context) top cfg dom;

  nixCfg = config.${top}.resolved.${dom}.nix;

  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) literalExpression mkEnable mkOption;
  inherit (lix.types.combinators) nullOr;
  inherit (lix.types.primitives) str;
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {
        inherit context;
        condition = !(nixCfg.enable or false);
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

    outputs = {
      programs = {
        nh = {
          enable = true;
          clean = {
            enable = true;
            extraArgs = "--keep-since ${cfg.keepSince} --keep ${cfg.keepCount}";
          };
          inherit (cfg) flake;
        };
      };
    };
  }
