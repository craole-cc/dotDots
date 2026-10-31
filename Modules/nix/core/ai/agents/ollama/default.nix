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
  inherit (lix.lists.transformation) unique;
  inherit (lix.schema.packages) selectedPackages;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.types.primitives) anything bool package str;
  inherit (lix.types.combinators) listOf nullOr;
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
          type = listOf str;
          readOnly = true;
          default = models.autocomplete.models;
          description = "Ordered code completion models from the host schema.";
        };
        active = mkOption {
          type = nullOr str;
          readOnly = true;
          default = models.autocomplete.active;
          description = "The preferred code completion model, or null when none is configured.";
        };
      };

      chat = {
        models = mkOption {
          type = listOf str;
          readOnly = true;
          default = models.chat.models;
          description = "Ordered chat models from the host schema.";
        };
        active = mkOption {
          type = nullOr str;
          readOnly = true;
          default = models.chat.active;
          description = "The preferred chat model, or null when none is configured.";
        };
      };

      disableDefaults = mkOption {
        type = bool;
        readOnly = true;
        default = host.ai.ollama.disableDefaults;
        description = "Whether hardware-derived models are disabled in the host schema.";
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
