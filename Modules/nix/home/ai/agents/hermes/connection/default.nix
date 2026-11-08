{
  cfg,
  config,
  resolve,
  pkgs,
  entryBetween,
  lix,
  ...
}: let
  inherit (lix.attrsets.construction) optionalAttrs;
  inherit (lix.attrsets.transformation) filterAttrs mapAttrs;
  inherit (lix.lists.predicates) all;
  inherit (lix.modules.construction) mkIf mkLayer;
  inherit (lix.strings.transformation) escapeShellArg;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.toolkit) platform write;
  inherit (lix.strings.transformation) trim;
  inherit (lix.types.combinators) listOf nullOr submodule;
  inherit (lix.types.primitives) bool str;

  active = filterAttrs (_name: profile: profile.enable) cfg.profiles;
  known = name: name == "default" || active ? ${name};
  optionalId = description:
    mkOption {
      type = nullOr str;
      default = null;
      inherit description;
    };

  #? Only fields that actually affect the gateway process belong in the
  #? restart trigger. Profile descriptions, bot titles, SOUL.md, and other
  #? home.file contents do NOT require a gateway restart; they are read at
  #? chat time or written by the profile activation script.
  gatewayTriggerPayload = {
    profiles =
      mapAttrs
      (_name: profile: {inherit (profile) enable settings bot;})
      cfg.profiles;
    inherit (config.services.hermes-agent) settings;
    inherit (cfg.gateway) multiplex routes;
  };
  telegramPython = pkgs.python3.withPackages (python: [python.python-dotenv]);
  defaults.gateway = {
    enable = true;
    multiplex = false;
    routes = [];
    telegram = {
      source = null;
      destination = "${cfg.home.path}/telegram.env";
    };
  };
  resolved = resolve {gateway = defaults.gateway // {multiplex = active != {};};};
in {
  inherit defaults;
  resolutions.gateway = mkLayer 1000 resolved.gateway;
  options.gateway = {
    telegram = {
      source = optionalId "Legacy runtime dotenv file from which activation extracts only TELEGRAM_ settings. Null disables extraction.";
      destination = mkOption {
        type = str;
        default = defaults.gateway.telegram.destination;
        description = "Private runtime Telegram environment file prepared before Hermes setup.";
      };
    };
    enable = mkEnable {
      description = "Hermes messaging gateway service";
      condition = defaults.gateway.enable;
    };
    multiplex = mkOption {
      type = bool;
      default = defaults.gateway.multiplex;
      description = "Serve named profiles in the existing gateway. Defaults on when profiles are declared.";
    };
    routes = mkOption {
      type = listOf (submodule {
        options = {
          name = mkOption {
            type = str;
            default = "";
            description = "Optional route label.";
          };
          platform = mkOption {
            type = str;
            default = "telegram";
            description = "Hermes platform receiving the message, such as telegram or discord.";
          };
          profile = mkOption {
            type = str;
            default = "default";
            description = "Declared profile that handles matching messages, or default.";
          };
          bot_profile = optionalId "Profile owning the receiving bot credential. Null uses the default bot.";
          user_id = optionalId "Exact sender identifier. Null leaves the sender unconstrained.";
          guild_id = optionalId "Server or workspace identifier.";
          chat_id = optionalId "Conversation or channel identifier.";
          thread_id = optionalId "Thread identifier.";
        };
      });
      default = [];
      description = ''
        Shared-bot routes, using Hermes's native route keys.
        Specificity follows Hermes's rule: the most-specific matching route wins.
        Precedence, most specific first:
          thread_id > chat_id > guild_id > user_id > platform-only.
        Ties between routes with the same specificity are rejected by Hermes at
        startup. Use bot_profile to pin the receiving credential independently
        of the handling profile.
      '';
    };
  };

  resolutions.settings = mkLayer 90 (optionalAttrs cfg.gateway.multiplex {
    # Hermes gives these canonical keys precedence over older nested settings.
    multiplex_profiles = true;
    profile_routes =
      map
      (filterAttrs (_key: value: value != null && value != ""))
      cfg.gateway.routes;
  });

  resolutions.environment.files = mkIf (cfg.gateway.telegram.source != null) [cfg.gateway.telegram.destination];

  outputs = {
    home.activation.hermesTelegramEnvironment = mkIf (cfg.gateway.telegram.source != null) (
      entryBetween ["hermesAgentSetup"] ["writeBoundary" "linkGeneration"] ''
        $DRY_RUN_CMD ${telegramPython}/bin/python ${./telegram_environment.py} \
          ${escapeShellArg cfg.gateway.telegram.source} \
          ${escapeShellArg cfg.gateway.telegram.destination}
      ''
    );

    services.hermes-agent.gateway = {inherit (cfg.gateway) enable;};

    systemd.user.services.hermes-agent.Unit.X-Restart-Triggers =
      mkIf
      (platform.isLinux && cfg.gateway.multiplex && config.services.hermes-agent.gateway.enable)
      [
        (write.json "hermes-team.json" gatewayTriggerPayload)
      ];

    assertions = [
      {
        assertion =
          cfg.gateway.telegram.source
          == null
          || (
            lix.strings.predicates.hasPrefix "/" cfg.gateway.telegram.source
            && lix.strings.predicates.hasPrefix "/" cfg.gateway.telegram.destination
            && cfg.gateway.telegram.source != cfg.gateway.telegram.destination
          );
        message = "Telegram migration requires distinct absolute runtime source and destination paths.";
      }
      {
        assertion = cfg.gateway.routes == [] || cfg.gateway.multiplex;
        message = "Hermes gateway.routes requires gateway.multiplex.";
      }
      {
        assertion = all (route: known route.profile && (route.bot_profile == null || known route.bot_profile)) cfg.gateway.routes;
        message = "Hermes gateway routes must reference default or enabled declared profiles.";
      }
      {
        assertion = all (route:
          (trim route.platform != "")
          && all (value: value == null || trim value != "")
          (with route; [bot_profile user_id guild_id chat_id thread_id]))
        cfg.gateway.routes;
        message = "Hermes gateway route platforms and supplied identifiers must not be empty.";
      }
    ];
  };
}
