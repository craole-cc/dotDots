{
  config,
  lix,
  src,
  ...
}: let
  inherit (lix.attrsets.construction) optionalAttrs;
  inherit (lix.modules.construction) mkContext mkConfig;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.types.combinators) attrsOf;
  inherit (lix.types.primitives) str;

  context = mkContext {
    inherit config;
    dom = "environment";
    mod = "aliases";
  };
  inherit (context) cfg;

  registry = {
    default =
      {
        #~@ File listing
        ll = "lsd --long --git --almost-all";
        lt = "lsd --tree";
        lr = "lsd --long --git --recursive";
      }
      // optionalAttrs (src != null) {
        #~@ Dotfiles management
        "edit-${src.name}" = "$EDITOR ${src.path}";
        "ide-${src.name}" = "$VISUAL ${src.path}";
        "push-${src.name}" = "gitui --directory ${src.path}";

        #~@ Nix REPL
        repl-host = "nix repl ${src.path}#nixosConfigurations.$(hostname)";
        "repl-${src.name}" = "nix repl ${src.path}#repl";

        #~@ Rebuild shortcuts
        "switch-${src.name}" = "sudo nixos-rebuild switch --flake ${src.path}";
        nxs = "push-${src.name}; switch-${src.name}";
        nxu = "push-${src.name}; switch-${src.name}; topgrade";
      };
  };
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {inherit context;};
      default = mkOption {
        description = "Default shell aliases";
        inherit (registry) default;
        type = attrsOf str;
      };
      extra = mkOption {
        description = "Additional shell aliases";
        default = {};
        type = attrsOf str;
      };
    };
    outputs = {
      environment.shellAliases = cfg.default // cfg.extra;
    };
  }
