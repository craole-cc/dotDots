{
  config,
  host,
  lix,
  osConfig ? {},
  pkgs,
  top,
  user,
  ...
}: let
  dom = "ai";
  sub = "providers";
  mod = "llmhop";
  context = mkContext {inherit config dom sub mod;};
  inherit (context) cfg;

  inherit (lix.attrsets.access) attrNames;
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.attrsets.construction) genAttrs listToAttrs nameValuePair;
  inherit (lix.lists.access) head tail;
  inherit (lix.lists.aggregation) concatMap;
  inherit (lix.lists.construction) optional asList;
  inherit (lix.lists.predicates) isIn;
  inherit (lix.lists.transformation) filter unique;
  inherit (lix.modules.construction) mkConfig mkContext mkIf;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.schema.packages) selectedPackages;
  inherit (lix.strings.transformation) replaceStrings;
  inherit (lix.toolkit) packages write;
  inherit (lix.types.combinators) attrsOf enum listOf nullOr;
  inherit (lix.types.primitives) anything package port str;
  inherit (pkgs) lib;

  #? Precedence: user schema -> system resolved -> host schema
  sources = {
    user = user.ai.${mod} or {};
    sys = osConfig.${top}.resolved.${dom}.${sub}.${mod}.explicit or {};
    host = host.ai.${mod} or {};
  };

  defaults = {
    cfg = recursiveUpdate sources.host (recursiveUpdate sources.sys sources.user);
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

  #? Route name -> repo, across every role
  routes = listToAttrs (
    concatMap
    (role: map (repo: nameValuePair (mkName repo) repo) cfg.models.${role}.includes)
    models.names
  );
  names = attrNames routes;

  #? One loopback port per worker, assigned in route-name order
  ports = listToAttrs (
    lib.imap0 (i: name: nameValuePair name (cfg.workerPortBase + i)) names
  );

  #? Same rendering rules as the NixOS module: `false` -> `--no-<key>`, lists repeat the flag
  flags = concatMap (key: let
    value = cfg.settings.${key};
  in
    if value == null
    then []
    else if value == true
    then ["--${key}"]
    else if value == false
    then ["--no-${key}"]
    else if lib.isList value
    then concatMap (item: ["--${key}" (toString item)]) value
    else ["--${key}" (toString value)]) (attrNames cfg.settings);

  routerConfig = write.json "llmhop.json" {
    inherit (cfg) host port;
    models = genAttrs names (name: {
      url = "http://127.0.0.1:${toString ports.${name}}";
    });
  };

  mkWorker = name: {
    Unit.Description = "llama.cpp worker for ${routes.${name}}";
    Service = {
      ExecStart = lib.escapeShellArgs (
        [
          "${cfg.package}/bin/llama-server"
          "--hf-repo"
          routes.${name}
          "--alias"
          name
          "--host"
          "127.0.0.1"
          "--port"
          (toString ports.${name})
        ]
        ++ flags
      );
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = ["default.target"];
  };

  router = {
    Unit = {
      Description = "llmhop router";
      After = map (name: "llama-cpp-${name}.service") names;
      Wants = map (name: "llama-cpp-${name}.service") names;
    };
    Service = {
      ExecStart = "${cfg.routerPackage}/bin/llmhop --config ${routerConfig}";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = ["default.target"];
  };
in
  mkConfig {
    inherit context;

    options = {
      enable = mkEnable {
        inherit context;
        condition = isIn [mod] (selectedPackages user);
      };

      package = mkOption {
        type = package;
        default = defaults.package;
        description = "The llama.cpp package used by the model workers.";
      };

      routerPackage = mkOption {
        type = package;
        default = packages.${mod};
        description = "The llmhop package that routes requests to the workers.";
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
        default = defaults.cfg.host or "127.0.0.1";
        example = "[::]";
        description = ''
          Address the router should listen on.
          Use "127.0.0.1" (the default) to only allow local connections.
        '';
      };

      port = mkOption {
        type = port;
        default = defaults.cfg.port or 11435;
        example = 11111;
        description = "Port the llmhop router listens on.";
      };

      workerPortBase = mkOption {
        type = port;
        default = defaults.cfg.workerPortBase or 18000;
        description = ''
          First loopback port handed to the llama-server workers.
          Workers take consecutive ports in route-name order.
        '';
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

      # No firewall on home-manager; kept for schema parity / documentation
      allowRemoteAccess = mkEnable {
        condition = defaults.cfg.allowRemoteAccess or false;
        description = ''
          Whether remote access is intended.
          Home-manager cannot open the firewall, so this only documents the
          intent (ensure the listen address is not loopback-only).
        '';
      };

      models = genAttrs models.names mkModelType;
    };

    outputs = {
      systemd.user.services = mkIf (cfg.enable && !(osConfig.services.${mod}.enable or false)) (
        {llmhop = router;}
        // listToAttrs (
          map (name: nameValuePair "llama-cpp-${name}" (mkWorker name)) names
        )
      );
    };
  }
