{
  config,
  host,
  lix,
  pkgs,
  ...
}: let
  dom = "ai";
  sub = "providers";
  mod = "ollama";
  context = mkContext {inherit config dom sub mod;};
  inherit (context) cfg;

  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.attrsets.access) attrNames;
  inherit (lix.attrsets.construction) genAttrs;
  inherit (lix.lists.access) head tail;
  inherit (lix.lists.aggregation) concatMap;
  inherit (lix.lists.construction) optional asList;
  inherit (lix.lists.predicates) isIn;
  inherit (lix.lists.transformation) filter unique;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.schema.packages) selectedPackages;
  inherit (lix.toolkit) packages;
  inherit (lix.types.combinators) attrsOf listOf nullOr;
  inherit (lix.types.primitives) port package str;
  inherit (lix.types.predicates) isString;
  inherit (lix.content.emptiness) isNotEmpty;

  defaults = {
    cfg = host.ai.${mod};
    coreThreshold = 4;
    package = let
      requested = defaults.cfg.package or null;
    in
      if isString requested
      then packages.${requested} or (pkgs.${requested} or null)
      else if requested != null
      then requested
      else if
        (isNotEmpty (host.hardware.gpu.primary or null))
        || (isNotEmpty (host.hardware.gpu.secondary or null))
      then packages.${mod}
      else packages."${mod}-cpu";
    models = {
      chat = [
        "qwen3:4b-instruct"
        "qwen3:0.6b"
      ];
      completion = [
        "qwen2.5-coder:1.5b-base-q4_K_M"
        "qwen2.5-coder:0.5b-base-q4_K_M"
      ];
    };
    variables = recursiveUpdate {
      OLLAMA_CONTEXT_LENGTH = "8192";
      OLLAMA_MAX_LOADED_MODELS = "1";
      OLLAMA_NUM_PARALLEL = "1";
    } (defaults.cfg.sessionVariables or (defaults.cfg.variables or {}));
  };
  models.names = attrNames defaults.models;

  mkModelType = role: {
    excludes = mkOption {
      description = ''
        Models that should never be used for ${role}, even if they appear
        in the includes list.
      '';
      default = [];
      type = listOf str;
    };
    includes = mkOption {
      description = ''
        Models available for ${role}, ordered by preference.
        The first model in this list is treated as the preferred one.
      '';
      default = unique (
        defaults.cfg.${role}.models or (asList (defaults.cfg.${role} or []))
        ++ optional cfg.allowDefaults (
          if (host.hardware.cpu.cores or 0) >= defaults.coreThreshold
          then head defaults.models.${role}
          else head (tail defaults.models.${role})
        )
      );
      apply =
        filter
        (model: model != "" && !(isIn [model] cfg.models.${role}.excludes));
      type = listOf str;
    };
    default = mkOption {
      description = ''
        The preferred model for ${role}.
        Automatically set to the first entry in `includes`, or null if none are configured.
      '';
      default =
        if cfg.models.${role}.includes != []
        then head cfg.models.${role}.includes
        else null;
      type = nullOr str;
      readOnly = true;
    };
  };
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {
        inherit context;
        condition = isIn [mod] (
          selectedPackages (host.users.data.primary or {})
        );
      };

      package = mkOption {
        type = package;
        default = defaults.package;
      };

      allowDefaults = mkEnable {
        condition = defaults.cfg.allowDefaults or true;
        description = ''
          Whether to automatically include hardware-appropriate default models.

          When enabled, a sensible model is chosen based on your CPU core count.
          Disable this to have full control over which models are available.
        '';
      };

      host = mkOption {
        type = str;
        default = "127.0.0.1";
        example = "[::]";
        description = ''
          Address the server should listen on.

          Use "127.0.0.1" (the default) to only allow local connections.
          Use "0.0.0.0" or "[::]" if you want the server reachable from other machines
          (you will also need to enable `allowRemoteAccess`).
        '';
      };

      port = mkOption {
        type = port;
        default = 11434;
        example = 11111;
        description = ''
          Port the server listens on.
        '';
      };

      environmentVariables = mkOption {
        description = ''
          Set arbitrary environment variables for the ${mod} service.

          Be aware that these are only seen by the ${mod} server (systemd service),
          not normal invocations like `${mod} run`.
          Since `${mod} run` is mostly a shell around the ${mod} server, this is usually sufficient.
        '';
        example = {
          OLLAMA_LLM_LIBRARY = "cpu";
          HIP_VISIBLE_DEVICES = "0,1";
        };
        default = defaults.variables;
        type = attrsOf str;
      };

      allowRemoteAccess = mkEnable {
        condition = false;
        description = ''
          Whether to allow remote access to the ${mod} service.

          Enabling this opens the configured port in the firewall so other
          machines on your network can reach ${mod}. Keep it disabled
          if you only use ${mod} locally.
        '';
      };
      models = genAttrs models.names mkModelType;
    };

    outputs = {
      services.${mod} = {
        inherit (cfg) enable environmentVariables package host port;
        openFirewall = cfg.allowRemoteAccess;
        loadModels = unique (
          concatMap (role: cfg.models.${role}.includes) models.names
        );
      };
    };
  }
