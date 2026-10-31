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

  inherit (lix.lists.predicates) isIn;
  inherit (lix.lists.access) head;
  inherit (lix.lists.transformation) unique;
  inherit (lix.lists.construction) optional toList;
  inherit (lix.schema.packages) selectedPackages;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.types.primitives) anything package str;
  inherit (lix.types.combinators) either listOf;
  inherit (lix.toolkit.packages) ollama;
  models = host.ai.${mod}.models or {};
in
  mkConfig {
    inherit context;
    options = {
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

      autocomplete = {
        models = mkOption {
          type = either str (listOf str);
          default = models.autocomplete.models or (models.autocomplete or []);
          apply = value:
            unique (toList value
              ++ optional (!cfg.disableDefaults) (
                if (host.hardware.cpu.cores or 0) >= 4
                then "qwen2.5-coder:1.5b-base-q4_K_M"
                else "qwen2.5-coder:0.5b-base-q4_K_M"
              ));
          description = "Code completion model or ordered list of models. The first is preferred; all are installed.";
        };

        active = mkOption {
          type = str;
          readOnly = true;
          default = head cfg.autocomplete.models;
          description = "The primary active code completion model.";
        };
      };

      chat = {
        models = mkOption {
          type = either str (listOf str);
          default = models.chat.models or (models.chat or []);
          apply = value:
            unique (toList value
              ++ optional (!cfg.disableDefaults) (
                if (host.hardware.cpu.cores or 0) >= 4
                then "qwen3:4b-instruct"
                else "qwen3:0.6b"
              ));
          description = "Chat model or ordered list of models. The first is preferred; all are installed.";
        };

        active = mkOption {
          type = str;
          readOnly = true;
          default = head cfg.chat.models;
          description = "The primary active chat model.";
        };
      };

      disableDefaults = mkEnable {
        condition = host.ai.ollama.disableDefaults or false;
        description = "Disable hardware-derived models. Otherwise they are appended after explicitly configured models, preserving priority and removing duplicates.";
      };

      service = mkOption {
        type = anything;
        default = {
          host = "127.0.0.1";
          loadModels = [];
        };
      };
    };

    outputs = {
      services.ollama =
        cfg.service
        // {
          inherit (cfg) enable package;
          loadModels = with cfg;
            unique (
              (service.loadModels or [])
              ++ autocomplete.models ++ chat.models
            );
        };

      environment.systemPackages = [cfg.package];
    };
  }
