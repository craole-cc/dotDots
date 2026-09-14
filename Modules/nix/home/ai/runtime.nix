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
      # Preserve Hermes's native ChatGPT/Codex OAuth route as the primary
      # experience. It uses the user's official ChatGPT plan sign-in; a
      # subscription session is not sent through third-party routers.
      HERMES_MODEL_PROVIDER = "openai-codex";
      # Terra is the sustainable Plus default for routine implementation. Keep
      # Astra available for deliberate escalation, rather than consuming the
      # smaller high-capability allowance on every ordinary Telegram turn.
      HERMES_MODEL_DEFAULT = "gpt-5.6-terra";
      # Hermes 0.21.2 has one enforceable delegation rail rather than
      # task-type-specific automatic routing. Pin that rail to Terra so a
      # future cheap front door cannot accidentally make Luna implement an
      # entire repository task itself. Sol is separately pinned to Hermes's
      # explicit `/review` rail for independent validation.
      HERMES_DELEGATION_PROVIDER = "openai-codex";
      HERMES_DELEGATION_MODEL = "gpt-5.6-terra";
      HERMES_DELEGATION_REASONING_EFFORT = "medium";
      HERMES_REVIEW_PROVIDER = "openai-codex";
      HERMES_REVIEW_MODEL = "gpt-5.6-sol";
      # The API-backed alternate lane is a named custom provider below. Its
      # traffic flows through Headroom then 9Router without changing the
      # native Plus/Codex default.
      HERMES_9ROUTER_PROVIDER = "custom:9router";
      HERMES_9ROUTER_BASE_URL = "http://${c.bindAddress}:${toString c.port}/v1";
      # The legacy Hermes desktop uses its default API-server port (8642).
      # Reserve an adjacent loopback port for the managed runtime so both can
      # coexist during the migration without competing for a listener.
      API_SERVER_PORT = "8643";

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
      HEADROOM_LOSSLESS = "1";
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
  # Services do not run the interactive devShell hook, so load the private
  # Hermes secrets file here.  The locally generated 9Router key is deliberately
  # distinct from upstream provider keys: it authenticates Hermes to Headroom
  # and 9Router, never to OpenRouter or NVIDIA directly.
  hermesWithPrivateSecrets = pkgs.writeShellApplication {
    name = "hermes-with-private-secrets";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      secrets_file="$HERMES_SECRETS_FILE"
      if [ -r "$secrets_file" ]; then
        if [ -L "$secrets_file" ] || [ ! -f "$secrets_file" ]; then
          echo "refusing non-regular Hermes secrets file: $secrets_file" >&2
          exit 1
        fi
        if [ "$(stat -c '%u' "$secrets_file")" != "$(id -u)" ] || [ $((0$(stat -c '%a' "$secrets_file") & 077)) -ne 0 ]; then
          echo "refusing Hermes secrets file not owned and private to this user: $secrets_file" >&2
          exit 1
        fi
        set -a
        # shellcheck disable=SC1090
        . "$secrets_file"
        set +a
      fi

      if [ -z "''${OPENAI_API_KEY:-}" ] && [ -n "''${NINE_ROUTER_API_KEY:-}" ]; then
        export OPENAI_API_KEY="$NINE_ROUTER_API_KEY"
      fi
      exec "$@"
    '';
  };
  hermesGateway = pkgs.writeShellApplication {
    name = "hermes-gateway-ai-runtime";
    runtimeInputs = agents.hermes.packages;
    text = ''
      exec ${hermesWithPrivateSecrets}/bin/hermes-with-private-secrets hermes-gateway
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
      exec ${hermesWithPrivateSecrets}/bin/hermes-with-private-secrets ${../../global/ai/agents/hermes/packages/scripts/launch-wayland.sh} ${agents.hermes.tools.desktop.exe} "$@"
    '';
  };
  configureHermes = pkgs.writeShellScript "configure-hermes-hindsight" ''
    export ${lib.concatStringsSep "\nexport " serviceEnvironment}
    export PATH="${lib.makeBinPath agents.hermes.packages}:$PATH"
    mkdir -p "$HERMES_HOME"
    ${configureHindsight}/bin/configure-hindsight --force
    # Hermes resolves its persistent profile before the process environment;
    # write the declared primary provider and default into that isolated
    # profile too.
    # `OPENAI_API_KEY` is loaded privately by the gateway wrapper, never saved
    # in this profile: the provider merely names its runtime environment key.
    hermes config set model.provider "$HERMES_MODEL_PROVIDER"
    hermes config unset model.base_url
    hermes config set model.default "$HERMES_MODEL_DEFAULT"
    # Keep implementation and validation on independently declared models.
    # The delegate_task API has no per-task model parameter in Hermes 0.21.2,
    # so this is deliberately one reliable worker rail, not a claim of fully
    # automatic semantic escalation.
    hermes config set delegation.provider "$HERMES_DELEGATION_PROVIDER"
    hermes config set delegation.model "$HERMES_DELEGATION_MODEL"
    hermes config set delegation.reasoning_effort "$HERMES_DELEGATION_REASONING_EFFORT"
    hermes config set auxiliary.review.provider "$HERMES_REVIEW_PROVIDER"
    hermes config set auxiliary.review.model "$HERMES_REVIEW_MODEL"
    hermes config set providers.9router.name 9Router
    hermes config set providers.9router.base_url "$HERMES_9ROUTER_BASE_URL"
    hermes config set providers.9router.key_env OPENAI_API_KEY
    hermes config set providers.9router.transport openai_chat
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
