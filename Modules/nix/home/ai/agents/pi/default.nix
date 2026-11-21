{
  config,
  inputs,
  system,
  lix,
  user,
  pkgs,
  ...
}: let
  inherit (lix.attrsets.construction) optionalAttrs;
  inherit (lix.lists.predicates) isIn;
  inherit (lix.modules.construction) mkConfig mkContext mkIf;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.packages.construction) hiPrio;
  inherit (lix.schema.packages) selectedPackages;
  inherit (lix.strings.construction) toInt toJSON;
  inherit (lix.strings.transformation) escapeShellArg escapeShellArgs;
  inherit (lix.toolkit.binaries) rust-script;
  inherit (lix.types.combinators) listOf;
  inherit (lix.types.primitives) package str;

  dom = "ai";
  sub = "agents";
  mod = "pi";

  context = mkContext {inherit config dom sub mod;};
  inherit (context) cfg;
  localProvider = config._.resolved.ai.providers.llmhop.defined;
  localModels = localProvider.models.chat.names;
  ollamaProvider = config._.resolved.ai.providers.ollama.defined;
  ollamaModels = ollamaProvider.models.chat.includes;
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
    };

    outputs = {
      home.packages = [cfg.package (hiPrio launcher)];
      home.file.".pi/agent/models.json" = mkIf ((localProvider.enable && localModels != []) || (ollamaProvider.enable && ollamaModels != [])) {
        text = toJSON {
          providers =
            optionalAttrs (localProvider.enable && localModels != []) {
              llmhop = {
                baseUrl = "http://${localProvider.host}:${toString localProvider.port}/v1";
                api = "openai-completions";
                apiKey = "local";
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
    };
  }
