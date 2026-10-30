{
  config,
  host,
  lix,
  ...
}: let
  inherit (lix.modules.construction) mkContext mkConfig;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.attrsets.construction) optionalAttrs;
  inherit (lix.strings.construction) concat;
  inherit (lix.strings.transformation) replaceStrings;
  inherit (lix.types.combinators) attrsOf;
  inherit (lix.types.primitives) str;
  inherit (lix.toolkit) binaries;
  join = concat ".";

  context = mkContext {
    inherit config;
    dom = "environment";
    mod = "aliases";
  };
  inherit (context) cfg;
  inherit (context.resolved.cfg.system.nix.explicit) repo;

  repl = let
    inherit (host) class;

    is.home = class == "home-manager";
    type = "${replaceStrings ["-manager"] [""] class}Configurations";

    #~@ A flake output entry, where _module, config, and options all live
    mkRoot = name: let
      root = join [type name];
    in {
      inherit root;
      target = root;
      config = join [root "config"];
      pkgs = join [root "_module" "args" "pkgs"];
      specialArgs = join [root "_module" "specialArgs"];
    };

    #~@ A home-manager user submodule: no _module is reachable from the system root
    mkNested = parent: user: let
      config = join [parent.config "home-manager" "users" user];
    in {
      root = null;
      target = config;
      inherit config;
      pkgs = null;
      specialArgs = null;
    };

    root = mkRoot "$(hostname)";
    core =
      if is.home
      then null
      else root;
    home =
      if is.home
      then root
      else mkNested root "$USER";
  in {inherit core home;};
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
            #~@ File listing
            ll = "lsd --long --git --almost-all";
            lt = "lsd --tree";
            lr = "lsd --long --git --recursive";

            #~@ Dotfiles management
            "edit-${repo.name}" = "$EDITOR ${repo.home}";
            "ide-${repo.name}" = "$VISUAL ${repo.home}";
            "push-${repo.name}" = "gitui --directory ${repo.home}";

            #~@ Nix REPL
            repl-home = "nix repl --show-trace ${repo.home}#${repl.home.target}";
            "repl-${repo.name}" = "nix repl ${repo.home}#repl";

            #~@ Nix helper shortcuts
            inherit (binaries) nhs nhr nhc;

            #~@ Rebuild shortcuts
            "switch-${repo.name}" = "sudo nixos-rebuild switch --flake ${repo.home}";
            nxs = "push-${repo.name}; switch-${repo.name}";
            nxu = "push-${repo.name}; switch-${repo.name}; topgrade";
          }
          // (
            optionalAttrs (repl.core != null)
            {repl-core = "nix repl --show-trace ${repo.home}#${repl.core.target}";}
          );
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
