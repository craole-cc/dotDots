{
  config,
  flake,
  lix,
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
      // optionalAttrs (flake != null) {
        #~@ Dotfiles management
        "edit-${flake.name}" = "$EDITOR ${flake.home}";
        "ide-${flake.name}" = "$VISUAL ${flake.home}";
        "push-${flake.name}" = "gitui --directory ${flake.home}";

        #~@ Nix REPL
        repl-host = "nix repl ${flake.home}#nixosConfigurations.$(hostname)";
        "repl-${flake.name}" = "nix repl ${flake.home}#repl";

        #~@ Rebuild shortcuts
        "switch-${flake.name}" = "sudo nixos-rebuild switch --flake ${flake.home}";
        nxs = "push-${flake.name}; switch-${flake.name}";
        nxu = "push-${flake.name}; switch-${flake.name}; topgrade";
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
