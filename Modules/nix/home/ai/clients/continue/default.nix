{
  config,
  lix,
  top,
  user,
  ...
}: let
  dom = "ai";
  sub = "clients";
  mod = "continue";
  context = mkContext {inherit config dom sub mod;};

  inherit (context) cfg;
  inherit (lix.attrsets.access) attrNames;
  inherit (lix.attrsets.transformation) filterAttrs mapAttrsToList;
  inherit (lix.lists.construction) concatLists;
  inherit (lix.lists.predicates) isIn;
  inherit (lix.modules.construction) mkConfig mkContext mkIf;
  inherit (lix.options.construction) mkEnable mkOption mkStrOption mkTrue;
  inherit (lix.strings.construction) concat;
  inherit (lix.schema.packages) selectedPackages;
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

  #? How each resolved provider is reached from Continue.
  #? llmhop is a router that speaks the OpenAI API, so it uses the `openai` id.
  providerFor = {
    ollama = {
      id = "ollama";
      path = "";
    };
    llmhop = {
      id = "openai";
      path = "/v1";
    };
  };

  #? Providers the user asked for that are also enabled on this host
  enabled =
    filterAttrs
    (name: provider: isIn [name] cfg.providers && (provider.explicit.enable or false))
    #? Single source of truth: the resolved provider configs
    config.${top}.resolved.${dom}.providers or {};

  defaults = {
    conf = concat "/" [".continue" "config.yaml"];
    providers = attrNames providerFor;
  };

  #? `role` is a provider-module role, which shares names with Continue's roles.
  #? `rolesFor` maps it to every Continue role that model should fill.
  mkModel = name: provider: role: model: let
    rolesFor = {
      chat = ["chat" "edit" "apply"];
      autocomplete = ["autocomplete"];
    };
    roles = rolesFor.${role} or (throw "continue: unsupported role '${role}'");
    inherit (providerFor.${name}) id path;
  in
    assert roleType.check roles; {
      name = model;
      provider = id;
      inherit model roles;
      apiBase = "http://${provider.host}:${toString provider.port}${path}";
    };

  derived = {
    name = "Local";
    version = "0.0.1";
    schema = "v1";
    models =
      concatLists (
        mapAttrsToList (
          name: {explicit, ...}:
            mapAttrsToList (role: model: mkModel name explicit role model.default) (
              filterAttrs
              (_: model: (model.default or null) != null)
              (explicit.models or {})
            )
        )
        enabled
      )
      ++ cfg.extraModels;
  };
in
  mkConfig {
    inherit context;

    options = {
      enable = mkEnable {
        inherit context;
        condition = isIn [mod] (selectedPackages user);
      };

      extraModels = mkOption {
        description = ''
          Extra model entries merged after any provider-derived models.
          Use for embeddings, cloud providers, or a pure non-local setup.
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

      providers = mkOption {
        description = ''
          Resolved providers whose models are included in the Continue config.
          A provider is only used when it is also enabled on this host.
          Set to `[]` to run Continue with only `extraModels` (cloud-only, etc.).
        '';
        default = defaults.providers;
        example = ["ollama"];
        type = listOf (enum defaults.providers);
      };

      configPath = mkStrOption {
        description = "Path of the generated Continue config.yaml, relative to $HOME.";
        default = defaults.conf;
      };

      generated = mkOption {
        description = "Preview of the config.yaml this module will write.";
        readOnly = true;
        default = write.yaml "continue-config.yaml" derived;
      };
    };

    outputs = {
      home.file.${cfg.configPath} = mkIf cfg.writeConfig {
        source = cfg.generated;
      };
    };
  }
