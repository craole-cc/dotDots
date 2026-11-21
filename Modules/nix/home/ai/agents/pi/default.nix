{
  config,
  inputs,
  system,
  lix,
  user,
  pkgs,
  ...
}: let
  inherit (lix.attrsets.construction) nameValuePair optionalAttrs;
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.attrsets.transformation) mapAttrs';
  inherit (lix.lists.predicates) isIn;
  inherit (lix.modules.construction) mkConfig mkContext mkIf;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.packages.construction) hiPrio;
  inherit (lix.schema.packages) selectedPackages;
  inherit (lix.strings.construction) toInt toJSON;
  inherit (lix.strings.transformation) escapeShellArg escapeShellArgs;
  inherit (lix.toolkit.binaries) rust-script;
  inherit (lix.types.combinators) attrsOf enum listOf nullOr;
  inherit (lix.types.primitives) package path str;

  dom = "ai";
  sub = "agents";
  mod = "pi";

  context = mkContext {inherit config dom sub mod;};
  inherit (context) cfg;
  localProvider = config._.resolved.ai.providers.llmhop.defined;
  localModels = localProvider.models.chat.names;
  ollamaProvider = config._.resolved.ai.providers.ollama.defined;
  ollamaModels = ollamaProvider.models.chat.includes;
  settings = recursiveUpdate cfg.settings (
    optionalAttrs (cfg.defaults.provider != null) {defaultProvider = cfg.defaults.provider;}
    // optionalAttrs (cfg.defaults.model != null) {defaultModel = cfg.defaults.model;}
    // optionalAttrs (cfg.defaults.thinkingLevel != null) {defaultThinkingLevel = cfg.defaults.thinkingLevel;}
  );
  launcher = pkgs.writeShellScriptBin "pi" ''
    exec ${escapeShellArg (toString rust-script)} ${escapeShellArg (toString ./environment.rs)} \
      ${escapeShellArgs cfg.credentials.sources} -- ${escapeShellArg "${cfg.package}/bin/pi"} "$@"
  '';
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
        default = inputs.llm-agents.packages.${system}.pi;
        description = "Pi agent harness package to expose in this user's profile.";
      };

      credentials.sources = mkOption {
        type = listOf str;
        default = let
          private = "${config.home.homeDirectory}/Private";
        in [
          "${private}/pi.env"
          "${private}/pi/.env"
          "${private}/pi/*.env"
        ];
        description = "Ordered runtime dotenv paths or glob patterns for Pi. Later files override earlier values; glob matches are sorted and missing files are skipped.";
      };

      extensions = mkOption {
        type = attrsOf path;
        default = {"codex-router.ts" = ./extensions/codex-router.ts;};
        description = "Pi extensions, keyed by file name, installed into extensions/ of the agent directory where Pi discovers them at startup and on /reload. Set to {} to install none.";
      };

      settings = mkOption {
        type = attrsOf (pkgs.formats.json {}).type;
        default = {};
        description = "Additional declarative Pi settings. Explicit startup defaults take precedence over matching settings keys.";
      };

      defaults = {
        provider = mkOption {
          type = nullOr str;
          default = null;
          description = "Startup provider, rendered as defaultProvider. Null leaves the startup choice to Pi.";
        };

        model = mkOption {
          type = nullOr str;
          default = null;
          description = "Startup model ID, rendered as defaultModel. Null leaves the startup choice to Pi.";
        };

        thinkingLevel = mkOption {
          type = nullOr (enum ["off" "minimal" "low" "medium" "high" "xhigh" "max"]);
          default = null;
          description = "Startup thinking level, rendered as defaultThinkingLevel.";
        };
      };
    };

    outputs = {
      home.packages = [cfg.package (hiPrio launcher)];
      #? settings.json is rendered only when a default is declared, and is then
      #? read-only: Pi can no longer persist its own deviceId, changelog marker,
      #? or Ctrl+S defaults. Keep them here instead of in the agent directory.
      home.file =
        {
          ".pi/agent/models.json" = mkIf ((localProvider.enable && localModels != []) || (ollamaProvider.enable && ollamaModels != [])) {
            text = toJSON {
              providers =
                optionalAttrs (localProvider.enable && localModels != []) {
                  llmhop = {
                    baseUrl = "http://${localProvider.host}:${toString localProvider.port}/v1";
                    api = "openai-completions";
                    apiKey = "local";
                    compat.maxTokensField = "max_tokens";
                    models =
                      map (id: {
                        inherit id;
                        contextWindow = localProvider.settings.ctx-size;
                        maxTokens = 2048;
                      })
                      localModels;
                  };
                }
                // optionalAttrs (ollamaProvider.enable && ollamaModels != []) {
                  ollama = {
                    baseUrl = "http://${ollamaProvider.host}:${toString ollamaProvider.port}/v1";
                    api = "openai-completions";
                    apiKey = "local";
                    compat.maxTokensField = "max_tokens";
                    models =
                      map (id: {
                        inherit id;
                        contextWindow = toInt ollamaProvider.environmentVariables.OLLAMA_CONTEXT_LENGTH;
                        maxTokens = 2048;
                      })
                      ollamaModels;
                  };
                };
            };
          };
        }
        // mapAttrs' (name: source:
          nameValuePair ".pi/agent/extensions/${name}" {
            inherit source;
            force = true;
          })
        cfg.extensions
        // optionalAttrs (settings != {}) {
          ".pi/agent/settings.json".text = toJSON settings;
        };
    };
  }
