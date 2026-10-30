{
  config,
  host,
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
  isStandaloneHome = host.class == "home-manager";
  output = rec {
    core =
      if host.class == "darwin"
      then "darwinConfigurations.$(hostname).config"
      else if isStandaloneHome
      then null
      else "nixosConfigurations.$(hostname).config";
    home =
      if isStandaloneHome
      then "homeConfigurations.$(hostname).config"
      else "${core}.home-manager.users.$USER";
  };

  registry = {
    default =
      {
        #~@ File listing
        ll = "lsd --long --git --almost-all";
        lt = "lsd --tree";
        lr = "lsd --long --git --recursive";

        #~@ Dotfiles management
        "edit-${repo.name}" = "$EDITOR ${repo.home}";
        "ide-${repo.name}" = "$VISUAL ${repo.home}";
        "push-${repo.name}" = "gitui --directory ${repo.home}";

        #~@ Nix REPL
        repl-home = "nix repl --show-trace ${repo.home}#${output.home}";
        "repl-${repo.name}" = "nix repl ${repo.home}#repl";

        #~@ Nix helper shortcuts
        inherit (lix.toolkit.binaries) nhs nhr nhc;

        #~@ Rebuild shortcuts
        "switch-${repo.name}" = "sudo nixos-rebuild switch --flake ${repo.home}";
        nxs = "push-${repo.name}; switch-${repo.name}";
        nxu = "push-${repo.name}; switch-${repo.name}; topgrade";
      }
      // (
        if output.core == null
        then {}
        else {
          repl-core = "nix repl --show-trace ${repo.home}#${output.core}";
        }
      );
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
