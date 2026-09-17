{
  config,
  inputs,
  system,
  lix,
  user,
  pkgs,
  ...
}: let
  dom = "ai";
  sub = "agents";
  mod = "codex";

  inherit (lix.lists.predicates) isIn;
  inherit (lix.lists.transformation) filter;
  inherit (lix.modules.construction) mkConfig mkContext mkIf mkMerge;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.types.combinators) attrsOf nullOr;
  inherit (lix.types.primitives) anything package path;

  context = mkContext {inherit config dom sub mod;};
  inherit (context) cfg;

  toml = pkgs.formats.toml {};
in
  mkConfig {
    inherit context;

    # Codex authentication and profiles are per-user state under ~/.codex.
    # `config` produces ~/.codex/config.toml. It supports models, providers,
    # MCP, sandboxing, profiles, and other public Codex settings; use provider
    # env_key/auth commands rather than placing credentials in this attrset.
    options = {
      enable = mkEnable {
        inherit context;
        condition = isIn ["codex"] (let
          domain = user.applications.${dom} or {};
        in
          (user.applications.allowed or [])
          ++ map (module: domain.${module}) (
            filter (module: domain ? ${module})
            ["primary" "secondary" "tertiary"]
          ));
      };

      package = mkOption {
        type = package;
        default = inputs.llm-agents.packages.${system}.${mod};
      };

      config = mkOption {
        type = attrsOf anything;
        default = {};
      };

      # A prewritten public config.toml takes precedence over generated config.
      # Do not use this for tokens: Nix path inputs are copied into the store.
      configFile = mkOption {
        type = nullOr path;
        default = null;
      };
    };

    outputs = mkMerge [
      {home.packages = [cfg.package];}
      (let
        inherit (cfg) configFile config;
      in
        mkIf (configFile != null || config != {}) {
          home.file.".${mod}/config.toml" =
            if configFile != null
            then {source = configFile;}
            else {source = toml.generate "config.toml" config;};
        })
    ];
  }
