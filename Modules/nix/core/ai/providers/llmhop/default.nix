{
  config,
  host,
  lix,
  pkgs,
  ...
}: let
  dom = "ai";
  sub = "providers";
  mod = "llmhop";
  context = mkContext {inherit config dom sub mod;};
  inherit (context) cfg;

  inherit (lix.attrsets.access) attrNames;
  inherit (lix.attrsets.construction) genAttrs listToAttrs nameValuePair;
  inherit (lix.lists.access) head tail;
  inherit (lix.lists.aggregation) concatMap;
  inherit (lix.lists.construction) optional asList;
  inherit (lix.lists.predicates) isIn;
  inherit (lix.lists.transformation) filter unique;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.schema.packages) selectedPackages;
  inherit (lix.strings.transformation) replaceStrings;
  inherit (lix.types.combinators) attrsOf enum listOf nullOr;
  inherit (lix.types.primitives) anything package port str;

  defaults = {
    cfg = host.ai.${mod} or {};
    coreThreshold = 4;

    #? Hugging Face repos, `repo[:quant]`, ordered large -> small.
    #? llama-server downloads them on first start.
    models = {
      chat = [
        "unsloth/Qwen3-4B-Instruct-2507-GGUF:Q4_K_M"
        "unsloth/Qwen3-0.6B-GGUF:Q8_0"
      ];
      autocomplete = [
        "ggml-org/Qwen2.5-Coder-1.5B-Q8_0-GGUF"
        "ggml-org/Qwen2.5-Coder-0.5B-Q8_0-GGUF"
      ];
    };

    #? Rendered by llmhop as `--<key> <value>` flags on every llama-server
    settings =
      {
        ctx-size = 8192;
        parallel = 1;
      }
      // (defaults.cfg.settings or {});

    package = pkgs.llama-cpp.override {
      cudaSupport = cfg.acceleration == "cuda";
      rocmSupport = cfg.acceleration == "rocm";
      vulkanSupport = cfg.acceleration == "vulkan";
    };
  };

  models.names = attrNames defaults.models;

  #? Route names only allow [[:alnum:].-], so sanitize the repo id
  mkName = replaceStrings ["/" ":" "_"] ["-" "-" "-"];

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
        Hugging Face repos (`repo[:quant]`) available for ${role}, ordered by preference.
        Unlike Ollama, every entry becomes a running llama-server that keeps
        its model in memory, so keep this list short.
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
    names = mkOption {
      description = ''
        Route names of `includes`: what clients send as the OpenAI `model`
        field and what llmhop advertises in `GET /v1/models`.
      '';
      default = map mkName cfg.models.${role}.includes;
      type = listOf str;
      readOnly = true;
    };
    default = mkOption {
      description = ''
        The route name of the preferred model for ${role}.
        Automatically set to the first entry in `names`, or null if none are configured.
      '';
      default =
        if cfg.models.${role}.names != []
        then head cfg.models.${role}.names
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
        description = "The llama.cpp package used by the model workers.";
      };

      acceleration = mkOption {
        type = nullOr (enum ["rocm" "cuda" "vulkan"]);
        default = defaults.cfg.acceleration or null;
        description = ''
          Hardware acceleration backend for llama.cpp.

          - `null`: CPU only
          - `"rocm"`: AMD GPUs
          - `"cuda"`: NVIDIA GPUs (requires `allowUnfree`)
          - `"vulkan"`: most GPUs via Vulkan
        '';
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
          Address the router should listen on.

          Use "127.0.0.1" (the default) to only allow local connections.
          Use "0.0.0.0" or "[::]" if you want the server reachable from other machines
          (you will also need to enable `allowRemoteAccess`).
        '';
      };

      port = mkOption {
        type = port;
        default = 11435;
        example = 11111;
        description = "Port the llmhop router listens on.";
      };

      settings = mkOption {
        type = attrsOf anything;
        default = defaults.settings;
        example = {
          ctx-size = 16384;
          flash-attn = "on";
        };
        description = ''
          llama-server flags applied to every model, rendered as `--<key> <value>`.
          `false` becomes `--no-<key>` and a list repeats the flag.
        '';
      };

      allowRemoteAccess = mkEnable {
        condition = false;
        description = ''
          Whether to allow remote access to the ${mod} router.

          Enabling this opens the configured port in the firewall so other
          machines on your network can reach ${mod}. Keep it disabled
          if you only use ${mod} locally.
        '';
      };

      models = genAttrs models.names mkModelType;
    };

    outputs = {
      services.${mod} = {
        gateway = {
          type = "llmhop";
          llmhop.listen.default = {
            inherit (cfg) host port;
            openFirewall = cfg.allowRemoteAccess;
          };
        };
        llama-cpp = {
          enable = true;
          inherit (cfg) package;
          modelSettings = cfg.settings;
          models = listToAttrs (
            concatMap
            (role:
              map
              (repo: nameValuePair (mkName repo) {model = repo;})
              cfg.models.${role}.includes)
            models.names
          );
        };
      };
    };
  }
