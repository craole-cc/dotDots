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

  inherit (lix.attrsets.construction) genAttrs optionalAttrs;
  inherit (lix.attrsets.transformation) filterAttrs mapAttrsToList;
  inherit (lix.lists.access) elemAt;
  inherit (lix.modules.construction) mkConfig mkContext mkIf;
  inherit (lix.options.construction) mkEnable mkOption mkStrOption mkTrue;
  inherit (lix.strings.access) match;
  inherit (lix.strings.predicates) hasInfix;
  inherit (lix.types.combinators) attrsOf enum listOf submodule;
  inherit (lix.types.primitives) anything;
  inherit (lix.toolkit) write;
  getExtension = file: elemAt (match ".*\\.([^.]+)$" file) 0;

  roleType = listOf (enum [
    "chat"
    "autocomplete"
    "embed"
    "rerank"
    "edit"
    "apply"
    "summarize"
  ]);
  configTypes = ["yaml" "json"];

  #? Single source of truth: the resolved Ollama provider config
  ollama = optionalAttrs cfg.useOllama (
    config.${top}.resolved.${dom}.providers.ollama.explicit or {}
  );

  defaults = {
    config = let
      mk = type: ".continue/config.${type}";
    in
      genAttrs configTypes mk
      // {default = "yaml";};
    host = ollama.host or "127.0.0.1";
    port = toString (ollama.port or 11434);
    apiBase = with defaults; "http://${host}:${port}";
  };

  # `role` is an Ollama-module role (same names as Continue's roles).
  # The table maps it to every Continue role that model should fill.
  # TODO: This looks weird
  mkModel = role: model: let
    roles =
      {
        chat = ["chat" "edit" "apply"];
        autocomplete = ["autocomplete"];
      }
      .${
        role
      }
      or (throw "continue: unsupported role '${role}'");
  in
    #? Validate values per a Continue model's `roles` (config.yaml schema v1)
    assert roleType.check
    roles; {
      name =
        if role == "autocomplete"
        then "${model} (autocomplete)"
        else model;
      provider = "ollama";
      inherit model roles;
      inherit (defaults) apiBase;
    };

  derived = {
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
        Write config to ${cfg.config.default}
      '';

      useOllama = mkTrue ''
        Include models from the Ollama module in the Continue config.
        Disable to run Continue with only `extraModels` (cloud-only, etc.).
      '';

      config = let
        mk = type:
          mkStrOption {
            description = "Path of the generated config.${type}, relative to $HOME.";
            default = defaults.config.${type};
          };
      in
        {
          default = mkStrOption {
            description = "Path of the generated Continue config.yaml, relative to $HOME.";
            default = defaults.config.default;
            apply = value:
              if hasInfix "/" value
              then value
              else if value == "yaml" || value == "json"
              then cfg.config.${value}
              else throw "continue: unsupported config format '${value}'; expected 'yaml', 'json', or a path";
          };
        }
        // genAttrs configTypes mk;

      generated = let
        ext = getExtension cfg.config.default;
        mk = type:
          mkOption {
            description = "Preview of the config.${type} this module will write.";
            readOnly = true;
            default = write.${type} "continue-config.${type}" derived;
            # type = attrsOf anything;
          };
      in
        {
          default = mkOption {
            description = "Preview of the generated config selected by config.default.";
            readOnly = true;
            default = cfg.generated.${ext};
          };
        }
        // genAttrs configTypes mk;
    };

    outputs = {
      home.file.${cfg.config.default} = mkIf cfg.writeConfig {
        source = cfg.generated.default;
      };
    };
  }
