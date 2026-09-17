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

  selectedApplications = let
    ai = user.applications.ai or {};
  in
    map (key: ai.${key}) (
      filter (key: ai ? ${key})
      ["primary" "secondary" "tertiary"]
    )
    ++ (user.applications.allowed or []);
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
        condition = isIn ["codex"] selectedApplications;
      };

      package = mkOption {
        type = package;
        default = inputs.llm-agents.packages.${system}.codex;
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
      (mkIf (cfg.configFile != null || cfg.config != {}) {
        home.file.".codex/config.toml" =
          if cfg.configFile != null
          then {source = cfg.configFile;}
          else {source = toml.generate "config.toml" cfg.config;};
      })
    ];
  }
