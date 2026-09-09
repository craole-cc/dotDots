{
  config,
  lix,
  ...
}: let
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

  repo = context.resolved.cfg.system.nix.explicit.repo;

  registry = {
    default = {
      #~@ File listing
      ll = "lsd --long --git --almost-all";
      lt = "lsd --tree";
      lr = "lsd --long --git --recursive";

      #~@ Dotfiles management
      "edit-${repo.name}" = "$EDITOR ${repo.home}";
      "ide-${repo.name}" = "$VISUAL ${repo.home}";
      "push-${repo.name}" = "gitui --directory ${repo.home}";

      #~@ Nix REPL
      repl-host = "nix repl ${repo.home}#nixosConfigurations.$(hostname)";
      "repl-${repo.name}" = "nix repl ${repo.home}#repl";

      #~@ Rebuild shortcuts
      "switch-${repo.name}" = "sudo nixos-rebuild switch --flake ${repo.home}";
      nxs = "push-${repo.name}; switch-${repo.name}";
      nxu = "push-${repo.name}; switch-${repo.name}; topgrade";
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
