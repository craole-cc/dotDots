{
  config,
  lix,
  ...
}: let
  inherit (lix.modules.construction) mkContext mkConfig mkDefault;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.attrsets.access) attrValues;
  inherit (lix.attrsets.transformation) mapAttrs;
  inherit (lix.lists.aggregation) concatMap;
  inherit (lix.types.combinators) attrsOf;
  inherit (lix.types.primitives) str;
  inherit (lix.toolkit) binariesFor;

  context = mkContext {
    inherit config;
    dom = "environment";
    mod = "aliases";
  };
  inherit (context) cfg;

  installedPackages =
    config.environment.systemPackages
    ++ concatMap (user: user.packages or []) (attrValues (config.users.users or {}))
    ++ concatMap (user: user.home.packages) (attrValues (config.home-manager.users or {}));

  current = {
    host = "$(hostname)";
    user = "$USER";
  };
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {inherit context;};
      default = mkOption {
        description = "Default shell aliases";
        type = attrsOf str;
        default = {
          which-host = "echo ${current.host}";
          which-user = "echo ${current.user}";

          #~@ File listing
          ll = "lsd --long --git --almost-all";
          lt = "lsd --tree";
          lr = "lsd --long --git --recursive";
        };
      };
      extra = mkOption {
        description = "Additional shell aliases";
        default = {};
        type = attrsOf str;
      };
    };
    outputs = {
      environment.shellAliases =
        (mapAttrs (_name: command: mkDefault command) (binariesFor installedPackages))
        // cfg.default
        // cfg.extra;
    };
  }
