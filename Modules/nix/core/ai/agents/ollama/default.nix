{
  config,
  host,
  lix,
  ...
}: let
  dom = "ai";
  sub = "agents";
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
  inherit (lix.toolkit.packages) ollama;
  inherit (lix.types.combinators) attrsOf listOf nullOr;
  inherit (lix.types.primitives) port package str;

  defaults = {
    cfg = host.ai.${mod};
    cores = 4;
    models = {
      completion = [
        "qwen2.5-coder:1.5b-base-q4_K_M"
        "qwen2.5-coder:0.5b-base-q4_K_M"
      ];
      chat = [
        "qwen3:4b-instruct"
        "qwen3:0.6b"
      ];
    };
    variables = recursiveUpdate {
      OLLAMA_CONTEXT_LENGTH = "8192";
      OLLAMA_MAX_LOADED_MODELS = "1";
      OLLAMA_NUM_PARALLEL = "1";
    } (defaults.cfg.sessionVariables or (defaults.cfg.variables or {}));
  };
  models = attrNames defaults.models;

  mkModelType = role: {
    ${role} = {
      models = mkOption {
        description = "Ordered ${role} models.";
        default = unique (
          defaults.cfg.${role}.models or (asList (defaults.cfg.${role} or []))
          ++ optional (!cfg.disableDefaults) (
            if (host.hardware.cpu.cores or 0) >= defaults.cores
            then head defaults.${role}
            else head (tail defaults.${role})
          )
        );
        apply = filter (model: model != "");
        type = listOf str;
      };
      active = mkOption {
        description = "The preferred model for ${role}, or null when none is configured.";
        default =
          if cfg.${role}.models != []
          then head cfg.${role}.models
          else null;
        type = nullOr str;
        readOnly = true;
      };
    };
  };
in
  mkConfig {
    inherit context;
    options =
      {
        enable = mkEnable {
          inherit context;
          condition = isIn ["ollama"] (
            selectedPackages (host.users.data.primary or {})
          );
        };

        package = mkOption {
          type = package;
          default = ollama;
        };

        disableDefaults = mkEnable {
          condition = host.ai.ollama.disableDefaults or false;
          description = "Whether hardware-derived models are disabled in the host schema.";
        };

        host = mkOption {
          type = str;
          default = "127.0.0.1";
          example = "[::]";
          description = ''
            The host address which the ollama server HTTP interface listens to.
          '';
        };

        port = mkOption {
          type = port;
          default = 11434;
          example = 11111;
          description = ''
            Which port the ollama server listens to.
          '';
        };

        sessionVariables = mkOption {
          description = ''
            Set arbitrary environment variables for the ollama service.

            Be aware that these are only seen by the ollama server (systemd service),
            not normal invocations like `ollama run`.
            Since `ollama run` is mostly a shell around the ollama server, this is usually sufficient.
          '';
          example = {
            OLLAMA_LLM_LIBRARY = "cpu";
            HIP_VISIBLE_DEVICES = "0,1";
          };
          default = defaults.variables;
          type = attrsOf str;
        };
      }
      // (genAttrs models mkModelType);

    outputs = {
      services.ollama = {
        inherit (cfg) enable package host port;
        environmentVariables = cfg.sessionVariables;
        loadModels = unique (
          concatMap (role: cfg.${role}.models) models
        );
      };

      environment = {
        inherit (cfg) sessionVariables;
        # systemPackages = [cfg.package];
      };
    };
  }
