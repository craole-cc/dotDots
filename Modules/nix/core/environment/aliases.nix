{
  config,
  lix,
  ...
}: let
  inherit (lix.modules.construction) mkContext mkConfig mkForce mkOverride;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.attrsets.access) attrValues;
  inherit (lix.attrsets.construction) optionalAttrs;
  inherit (lix.attrsets.transformation) mapAttrs;
  inherit (lix.lists.aggregation) concatMap;
  inherit (lix.types.combinators) attrsOf;
  inherit (lix.types.primitives) str;
  inherit (lix.toolkit) commandsFor;

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

  commands = commandsFor installedPackages;

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
        default =
          {
            which-host = "echo ${current.host}";
            which-user = "echo ${current.user}";
          }
          // optionalAttrs (commands.aliases ? lsdLong) {
            #~@ File listing overrides
            ll = commands.aliases.lsdLong;
            lt = commands.aliases.lsdTree;
            lr = commands.aliases.lsdRecursive;
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
        (mapAttrs (_name: command: mkOverride 1400 command) commands.binaries)
        // (mapAttrs (_name: command: mkForce command) (
          commands.aliases
          // cfg.default
          // cfg.extra
        ));
    };
  }
