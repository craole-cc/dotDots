{
  config,
  host,
  lix,
  top,
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

  current = {
    host = "$(hostname)";
    user = "$USER";
  };

  repl = let
    inherit (host) class;
    type = "${replaceStrings ["-manager"] [""] class}Configurations";

    #~@ The `_` namespace of a config: target, resolved, outputs
    mkTop = config: let
      target = join [config top];
    in {
      inherit target;
      resolved = join [target "resolved"];
      outputs = join [target "outputs"];
    };

    #~@ A flake output entry, where _module, config, and options all live
    mkRoot = name: let
      target = join [type name];
      config = join [target "config"];
      module = [target "_module"];
    in {
      inherit target config;
      top = mkTop config;
      pkgs = join (module ++ ["args" "pkgs"]);
      specialArgs = join (module ++ ["specialArgs"]);
    };

    #~@ A home-manager user submodule: no _module is reachable from the system root
    mkNested = parent: user: let
      config = join [parent.config "home-manager" "users" user];
    in {
      inherit config;
      target = config;
      top = mkTop config;
    };

    core = mkRoot current.host;
  in
    if class == "home-manager"
    then {home = core;}
    else {
      inherit core;
      home = mkNested core current.user;
    };

  #~@ Open a repl scoped to a flake attribute path
  mkRepl = scope: "nix repl --show-trace ${repo.home}#${scope}";

  #~@ repl-<name>, repl-<name>-resolved, repl-<name>-outputs
  mkReplAliases = name: scope: {
    "repl-${name}" = mkRepl scope.target;
    "repl-${name}-resolved" = mkRepl scope.top.resolved;
    "repl-${name}-outputs" = mkRepl scope.top.outputs;
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

            #~@ File listing
            ll = "lsd --long --git --almost-all";
            lt = "lsd --tree";
            lr = "lsd --long --git --recursive";

            #~@ Dotfiles management
            "edit-${repo.name}" = "$EDITOR ${repo.home}";
            "ide-${repo.name}" = "$VISUAL ${repo.home}";
            "push-${repo.name}" = "gitui --directory ${repo.home}";

            #~@ Nix REPL
            "repl-${repo.name}" = mkRepl "repl";

            #~@ Nix helper shortcuts
            inherit (binaries) nhs nhr nhc;

            #~@ Rebuild shortcuts
            "switch-${repo.name}" = "sudo nixos-rebuild switch --flake ${repo.home}; date";
            nxs = "push-${repo.name}; switch-${repo.name}";
            nxu = "push-${repo.name}; switch-${repo.name}; topgrade";
          }
          // mkReplAliases "home" repl.home
          // optionalAttrs (repl ? core) (mkReplAliases "core" repl.core);
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
