{
  config,
  lix,
  top,
  ...
}: let
  dom = "ai";
  sub = "clients";
  mod = "continue";
  context = mkContext {inherit config dom sub mod;};
  inherit (context) cfg;

  inherit (lix.attrsets.construction) optionalAttrs;
  inherit (lix.attrsets.transformation) filterAttrs mapAttrsToList;
  inherit (lix.modules.construction) mkConfig mkContext mkIf;
  inherit (lix.options.construction) mkEnable mkOption mkStrOption mkTrue;
  inherit (lix.toolkit) write;
  inherit (lix.types.combinators) attrsOf enum listOf submodule;
  inherit (lix.types.primitives) anything;

  #? Valid values for a Continue model's `roles` (config.yaml schema v1)
  roleType = listOf (enum [
    "chat"
    "autocomplete"
    "embed"
    "rerank"
    "edit"
    "apply"
    "summarize"
  ]);

  #? Single source of truth: the resolved Ollama provider config
  ollama = optionalAttrs cfg.useOllama (
    config.${top}.resolved.${dom}.providers.ollama.explicit or {}
  );

  defaults = {
    conf = ".continue/config.yaml";
    host = ollama.host or "127.0.0.1";
    port = toString (ollama.port or 11434);
    apiBase = with defaults; "http://${host}:${port}";
  };

  mkModel = role: model: let
    rolesFor = {
      chat = ["chat" "edit" "apply"];
      autocomplete = ["autocomplete"];
    };
    roles = rolesFor.${role} or (throw "continue: unsupported role '${role}'");
  in
    assert roleType.check roles; {
      name = model;
      provider = "ollama";
      inherit model roles;
      inherit (defaults) apiBase;
    };
in
  mkConfig {
    inherit context;

    options = {
      enable = mkEnable {
        inherit context;
        condition = true;
        # condition = isIn [mod] (selectedPackages user);
      };

      extraModels = mkOption {
        description = ''
          Extra model entries merged after any Ollama-derived models.
          Use for embeddings, cloud providers, or a pure non-Ollama setup.
          `roles` is required and validated against Continue's role list.
        '';
        example = [
          {
            name = "Nomic Embed";
            provider = "ollama";
            model = "nomic-embed-text";
            roles = ["embed"];
          }
          {
            name = "Claude Sonnet";
            provider = "anthropic";
            model = "claude-sonnet-4";
            #? Prefer env / secrets. Do not put real keys in the store
            roles = ["chat" "edit" "apply"];
          }
        ];
        default = [];
        type = listOf (submodule {
          freeformType = attrsOf anything;
          options.roles = mkOption {
            description = "Roles this model fills in Continue.";
            type = roleType;
          };
        });
      };

      writeConfig = mkTrue ''
        Write config to ${cfg.configPath}
      '';

      useOllama = mkTrue ''
        Include models from the Ollama module in the Continue config.
        Disable to run Continue with only `extraModels` (cloud-only, etc.).
      '';

      configPath = mkStrOption {
        description = "Path of the generated Continue config.yaml, relative to $HOME.";
        default = defaults.conf;
      };

      generated = mkOption {
        description = "Preview of the config.yaml this module will write.";
        readOnly = true;
        default = write.yaml "continue-config.yaml" {
          name = "Local";
          version = "0.0.1";
          schema = "v1";
          models =
            mapAttrsToList (role: model: mkModel role model.default) (
              filterAttrs
              (_: model: (model.default or null) != null)
              (ollama.models or {})
            )
            ++ cfg.extraModels;
        };
      };
    };

    outputs = {
      home.file.${cfg.configPath} = mkIf cfg.writeConfig {
        source = cfg.generated;
      };
    };
  }
