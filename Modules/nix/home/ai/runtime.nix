{
  config,
  host,
  inputs,
  lib,
  lix,
  pkgs,
  user,
  ...
} @ args: let
  inherit (lib.hm.dag) entryAfter;
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (pkgs.lib) unique;
  inherit (pkgs.lib.strings) toLower;

  cfg = host.shells.ai;
  h = cfg.hindsight;
  r = cfg.nineRouter;
  c = cfg.headroom;
  hostBank = "${h.bankPrefix}-${toLower host.name}";

  runtimeName = "hermes-hindsight-headroom-9router";
  dataRoot = "${config.xdg.dataHome}/${cfg.directory}";
  cacheRoot = "${config.xdg.cacheHome}/${cfg.directory}";
  runtimeHome = "${dataRoot}/${runtimeName}/${cfg.instance}";
  # Keep Hermes's externally visible state home below the Linux AF_UNIX path
  # limit.  Its target remains in the normal per-runtime state tree, while
  # this short, host-specific alias is the primary user-facing scratchpad.
  hermesStateHome = "${runtimeHome}/${cfg.hermes.state}";
  hermesHome = "${dataRoot}/hermes-${toLower host.name}";
  privateRoot = "${config.home.homeDirectory}/Private";
  hindsightData = "${dataRoot}/hindsight/${cfg.instance}";
  hindsightCache = "${cacheRoot}/hindsight/${cfg.instance}";
  hindsightSecrets = "${privateRoot}/${h.secrets}";
  nineRouterData = "${runtimeHome}/${r.state}";
  nineRouterCache = "${cacheRoot}/${runtimeName}/${cfg.instance}/${r.state}/npm";
  headroomData = "${runtimeHome}/${c.state}";
  headroomConfig = "${headroomData}/config";
  headroomCache = "${cacheRoot}/${runtimeName}/${cfg.instance}/${c.state}/uv";

  aiPaths = {
    xdg = {
      data.local = config.xdg.dataHome;
      cache.local = config.xdg.cacheHome;
      config.local = config.xdg.configHome;
    };
    home.private.local = privateRoot;
  };
  shared = import ../../global/shared (args // {paths = aiPaths;});
  aiArgs =
    (recursiveUpdate args shared)
    // {
      inherit cfg;
      paths = aiPaths;
      hindsightBank = hostBank;
    };
  agents = import ../../global/ai/agents aiArgs;
  context = import ../../global/ai/context aiArgs;
  memory = import ../../global/ai/memory aiArgs;
  router = import ../../global/ai/router aiArgs;
  hindsightIntegration = import ../../global/ai/presets/hermes/hindsight-integration.nix aiArgs;
  configureHindsight = builtins.head hindsightIntegration.packages;

  environment =
    memory.hindsight.env
    // {
      AI_PRESET = runtimeName;
      AI_INSTANCE = cfg.instance;
      AI_HOME = runtimeHome;
      AI_CACHE_DIR = "${cacheRoot}/${runtimeName}/${cfg.instance}";
      HERMES_HOME = hermesHome;
      HERMES_GATEWAY_CFG = "${hermesHome}/${cfg.hermes.gateway}";
      HERMES_SECRETS_FILE = "${privateRoot}/${cfg.hermes.secrets}";
      HERMES_DISABLE_LAZY_INSTALLS = "1";
      # Use the local OpenAI-compatible route, rather than Hermes's distinct
      # `openai-codex` OAuth backend which talks to ChatGPT directly.
      HERMES_MODEL_PROVIDER = "openai";
      HERMES_MODEL_BASE_URL = "http://${c.bindAddress}:${toString c.port}/v1";
      HERMES_MODEL_DEFAULT = "cx/gpt-6-astra";

      HINDSIGHT_SECRETS_FILE = hindsightSecrets;
      HINDSIGHT_RUNTIME_KIND = h.runtime;
      HINDSIGHT_DATA_DIR = hindsightData;
      HINDSIGHT_CACHE_DIR = hindsightCache;
      HINDSIGHT_BIND_ADDRESS = cfg.bindAddress;
      HINDSIGHT_API_PORT = toString h.ports.api;
      HINDSIGHT_MCP_PORT = toString h.ports.mcp;
      HINDSIGHT_UI_PORT = toString h.ports.ui;
      HINDSIGHT_API_URL = "http://${cfg.bindAddress}:${toString h.ports.api}";
      HINDSIGHT_UI_URL = "http://${cfg.bindAddress}:${toString h.ports.ui}";
      HINDSIGHT_LLM_BACKEND = h.llm.backend;
      HINDSIGHT_LLM_BASE_URL = h.llm.baseUrl;
      HINDSIGHT_LLM_MODEL = h.llm.model;
      HINDSIGHT_REFLECT_LLM_MODEL = h.llm.reflectModel;
      HINDSIGHT_MODE = h.mode;
      HINDSIGHT_BANK_ID = hostBank;
      HINDSIGHT_RECALL_BUDGET = h.recallBudget;
      HINDSIGHT_COMPOSE_PROJECT = "hindsight-${cfg.instance}";
      HINDSIGHT_CONTAINER_NAME = "hindsight-${cfg.instance}";

      NINE_ROUTER_DATA_DIR = nineRouterData;
      NINE_ROUTER_NPM_CACHE = nineRouterCache;
      NINE_ROUTER_BIND_ADDRESS = r.bindAddress;
      NINE_ROUTER_PORT = toString r.port;
      NINE_ROUTER_BASE_URL = "http://${r.bindAddress}:${toString r.port}/v1";

      HEADROOM_WORKSPACE_DIR = headroomData;
      HEADROOM_CONFIG_DIR = headroomConfig;
      HEADROOM_UV_CACHE = headroomCache;
      HEADROOM_HOST = c.bindAddress;
      HEADROOM_PORT = toString c.port;
      HEADROOM_BASE_URL = "http://${c.bindAddress}:${toString c.port}";
      HEADROOM_SAVINGS_PROFILE = "coding";
      HEADROOM_MODE = "token";
      HEADROOM_CODE_AWARE_ENABLED = "1";
      HEADROOM_TELEMETRY = "on";
      HEADROOM_PROVIDER_NAME = "9Router";
      # Headroom owns the OpenAI `/v1` path segment when forwarding. Its
      # upstream must therefore be the 9Router origin, not its client-facing
      # OpenAI base URL (which already ends in `/v1`).
      OPENAI_TARGET_API_URL = "http://${r.bindAddress}:${toString r.port}";
      OPENAI_BASE_URL = "http://${c.bindAddress}:${toString c.port}/v1";
    };

  serviceEnvironment = lib.mapAttrsToList (name: value: "${name}=${value}") environment;
  hermesGatewayReady = pkgs.writeShellApplication {
    name = "hermes-gateway-ready";
    runtimeInputs = [pkgs.gnugrep];
    text = ''
      env_file="$HERMES_HOME/.env"
      test -f "$env_file"
      grep -q '^TELEGRAM_BOT_TOKEN=.' "$env_file"
      grep -q '^TELEGRAM_ALLOWED_USERS=.' "$env_file"
    '';
  };
  hermesGateway = pkgs.writeShellApplication {
    name = "hermes-gateway-ai-runtime";
    runtimeInputs = agents.hermes.packages;
    text = ''
      exec hermes-gateway
    '';
  };
  # Hermes Desktop uses Electron's single-instance lock.  A separate user-data
  # directory is therefore required in addition to a separate HERMES_HOME if
  # the managed runtime and an existing/legacy desktop are to run together.
  hermesDesktopAiRuntime = pkgs.writeShellApplication {
    name = "hermes-desktop-ai-runtime";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      export ${lib.concatStringsSep "\nexport " serviceEnvironment}
      export HERMES_DESKTOP_USER_DATA_DIR="$HERMES_HOME/desktop-user-data"
      mkdir -p "$HERMES_DESKTOP_USER_DATA_DIR"
      exec ${../../global/ai/agents/hermes/packages/scripts/launch-wayland.sh} ${agents.hermes.tools.desktop.exe} "$@"
    '';
  };
  configureHermes = pkgs.writeShellScript "configure-hermes-hindsight" ''
    export ${lib.concatStringsSep "\nexport " serviceEnvironment}
    export PATH="${lib.makeBinPath agents.hermes.packages}:$PATH"
    mkdir -p "$HERMES_HOME"
    exec ${configureHindsight}/bin/configure-hindsight --force
  '';
in
  lib.mkIf (user.name == "craole") {
    home = {
      packages = unique (
        agents.hermes.packages
        ++ [
          context.headroom.packagesStart
          memory.hindsight.packagesServiceStart
          memory.hindsight.packagesUiStart
          router."nine-router".packagesStart
          hermesGateway
          hermesDesktopAiRuntime
        ]
        ++ hindsightIntegration.packages
      );
      sessionVariables = environment;
      activation.linkManagedHermesHome = entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg hermesStateHome}
        if [ -L ${lib.escapeShellArg hermesHome} ]; then
          if [ "$(${pkgs.coreutils}/bin/readlink -f ${lib.escapeShellArg hermesHome})" != ${lib.escapeShellArg hermesStateHome} ]; then
            echo "refusing to replace unexpected managed Hermes home link: ${hermesHome}" >&2
            exit 1
          fi
        elif [ -e ${lib.escapeShellArg hermesHome} ]; then
          echo "refusing to replace existing managed Hermes home: ${hermesHome}" >&2
          exit 1
        else
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -s ${lib.escapeShellArg hermesStateHome} ${lib.escapeShellArg hermesHome}
        fi
      '';
      activation.configureHermesHindsight = entryAfter ["linkManagedHermesHome"] ''
        $DRY_RUN_CMD ${configureHermes}
      '';
    };

    # `xdg.desktopEntries` is incompatible with the pinned Nixpkgs version's
    # removed `extraConfig` option.  Keep the menu entry declarative through
    # Home Manager's stable XDG data-file interface instead.
    xdg.dataFile."applications/hermes-desktop-ai-runtime.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Hermes Desktop (AI runtime)
      GenericName=Hermes Assistant
      Comment=Hermes Desktop using the local Headroom, 9Router, and Hindsight runtime
      Exec=hermes-desktop-ai-runtime %U
      Terminal=false
      Categories=Utility;
    '';

    # `ai-runtime.target` is enabled at user-manager start. On NixOS, the
    # companion core module enables lingering for interactive users so this
    # happens at boot too, before a graphical/login shell is opened.
    systemd.user.targets.ai-runtime = {
      Unit = {
        Description = "dotDots local AI runtime";
        Wants = [
          "ai-9router.service"
          "ai-headroom.service"
          "ai-hindsight.service"
          "ai-hindsight-ui.service"
          "ai-hermes-gateway.service"
        ];
        After = [
          "ai-9router.service"
          "ai-headroom.service"
          "ai-hindsight.service"
          "ai-hindsight-ui.service"
          "ai-hermes-gateway.service"
        ];
      };
      Install.WantedBy = ["default.target"];
    };

    systemd.user.services = {
      ai-9router = {
        Unit = {
          Description = "9Router OpenAI-compatible local router";
          After = ["network-online.target"];
          Wants = ["network-online.target"];
          PartOf = ["ai-runtime.target"];
        };
        Service = {
          ExecStart = "${router."nine-router".packagesStart}/bin/9router-start";
          Environment = serviceEnvironment;
          Restart = "on-failure";
          RestartSec = 5;
        };
      };

      ai-headroom = {
        Unit = {
          Description = "Headroom coding context proxy";
          Requires = ["ai-9router.service"];
          After = ["ai-9router.service"];
          PartOf = ["ai-runtime.target"];
        };
        Service = {
          ExecStart = "${context.headroom.packagesStart}/bin/headroom-start";
          Environment = serviceEnvironment;
          Restart = "on-failure";
          RestartSec = 5;
        };
      };

      ai-hindsight = {
        Unit = {
          Description = "Hindsight local memory API";
          After = ["network-online.target"];
          Wants = ["network-online.target"];
          PartOf = ["ai-runtime.target"];
        };
        Service = {
          ExecStart = "${memory.hindsight.packagesServiceStart}/bin/hindsight-service-start";
          Environment = serviceEnvironment;
          Restart = "on-failure";
          RestartSec = 5;
        };
      };

      ai-hindsight-ui = {
        Unit = {
          Description = "Hindsight local Control Plane UI";
          Requires = ["ai-hindsight.service"];
          After = ["ai-hindsight.service"];
          PartOf = ["ai-runtime.target"];
        };
        Service = {
          ExecStart = "${memory.hindsight.packagesUiStart}/bin/hindsight-ui-start";
          Environment = serviceEnvironment;
          Restart = "on-failure";
          RestartSec = 5;
        };
      };

      # This is deliberately separate from the interactive Hermes client.
      # It starts only after Telegram credentials have been written to the
      # isolated managed Hermes home, so a fresh machine does not spin in a
      # restart loop before its user creates or configures a bot.
      ai-hermes-gateway = {
        Unit = {
          Description = "Hermes Telegram gateway for the local AI runtime";
          Requires = [
            "ai-headroom.service"
            "ai-hindsight.service"
          ];
          After = [
            "ai-headroom.service"
            "ai-hindsight.service"
          ];
          PartOf = ["ai-runtime.target"];
        };
        Service = {
          ExecCondition = "${hermesGatewayReady}/bin/hermes-gateway-ready";
          ExecStart = "${hermesGateway}/bin/hermes-gateway-ai-runtime";
          Environment = serviceEnvironment;
          Restart = "on-failure";
          RestartSec = 5;
        };
      };
    };
  }
