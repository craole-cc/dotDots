{
  args,
  core,
  ...
}: let
  inherit (args) pkgs;
  inherit (pkgs) mkShell;

  cfg = args.host.shells.ai or (throw "AI shell configuration is missing from host.shells.ai");
  paths = args.paths;
  aiArgs = args // {inherit cfg paths;};

  agents = import ./agents aiArgs;
  context = import ./context aiArgs;
  memory = import ./memory aiArgs;
  router = import ./router aiArgs;
  presets = import ./presets (aiArgs // {inherit agents context memory router;});

  componentEnv = {
    hindsight = let
      h = cfg.hindsight;
    in {
      HINDSIGHT_API_URL = "http://${cfg.bindAddress}:${toString h.ports.api}";
      HINDSIGHT_BIND_ADDRESS = cfg.bindAddress;
      HINDSIGHT_API_PORT = toString h.ports.api;
      HINDSIGHT_MCP_PORT = toString h.ports.mcp;
      HINDSIGHT_UI_PORT = toString h.ports.ui;
      HINDSIGHT_IMAGE = h.image;
      HINDSIGHT_LLM_BACKEND = h.llm.backend;
      HINDSIGHT_LLM_BASE_URL = h.llm.baseUrl;
      HINDSIGHT_LLM_MODEL = h.llm.model;
      HINDSIGHT_REFLECT_LLM_MODEL = h.llm.reflectModel;
      HINDSIGHT_MODE = h.mode;
      HINDSIGHT_BANK_ID = h.bank;
      HINDSIGHT_RECALL_BUDGET = h.recallBudget;
      HINDSIGHT_COMPOSE_PROJECT = "hindsight-${cfg.instance}";
      HINDSIGHT_CONTAINER_NAME = "hindsight-${cfg.instance}";
    };

    mem0 = {
      MEM0_BASE_URL = "http://${cfg.bindAddress}:${toString cfg.mem0.port}";
    };

    omniroute = {
      OMNIROUTE_PORT = toString cfg.omniroute.port;
      OMNIROUTE_BASE_URL = "http://${cfg.omniroute.bindAddress}:${toString cfg.omniroute.port}/v1";
    };

    "nine-router" = {
      NINE_ROUTER_PORT = toString cfg.nineRouter.port;
      NINE_ROUTER_BIND_ADDRESS = cfg.nineRouter.bindAddress;
      NINE_ROUTER_BASE_URL = "http://${cfg.nineRouter.bindAddress}:${toString cfg.nineRouter.port}/v1";
    };

    headroom = {
      HEADROOM_HOST = cfg.headroom.bindAddress;
      HEADROOM_PORT = toString cfg.headroom.port;
      HEADROOM_BASE_URL = "http://${cfg.headroom.bindAddress}:${toString cfg.headroom.port}";
    };
  };

  componentHook = {
    hindsight = ''
      export HINDSIGHT_SECRETS_FILE="''${HINDSIGHT_SECRETS_FILE:-${paths.home.private.local}/${cfg.hindsight.secrets}}"
    '';

    omniroute = ''
      export OMNIROUTE_DATA_DIR="''${OMNIROUTE_DATA_DIR:-${paths.xdg.data.local}/${cfg.directory}/${cfg.omniroute.state}}"
      export OMNIROUTE_NPX_CACHE="''${OMNIROUTE_NPX_CACHE:-${paths.xdg.cache.local}/${cfg.directory}/${cfg.omniroute.state}/npx}"
      export OMNIROUTE_SESSION="''${OMNIROUTE_SESSION:-${cfg.omniroute.session}}"
    '';

    "nine-router" = ''
      export NINE_ROUTER_DATA_DIR="''${NINE_ROUTER_DATA_DIR:-${paths.xdg.data.local}/${cfg.directory}/${cfg.nineRouter.state}}"
      export NINE_ROUTER_NPM_CACHE="''${NINE_ROUTER_NPM_CACHE:-${paths.xdg.cache.local}/${cfg.directory}/${cfg.nineRouter.state}/npm}"
      export NINE_ROUTER_SESSION="''${NINE_ROUTER_SESSION:-${cfg.nineRouter.session}}"
    '';

    headroom = ''
      export HEADROOM_WORKSPACE_DIR="''${HEADROOM_WORKSPACE_DIR:-${paths.xdg.data.local}/${cfg.directory}/${cfg.headroom.state}}"
      export HEADROOM_CONFIG_DIR="''${HEADROOM_CONFIG_DIR:-${paths.xdg.config.local}/${cfg.directory}/${cfg.headroom.state}}"
      export HEADROOM_UV_CACHE="''${HEADROOM_UV_CACHE:-${paths.xdg.cache.local}/${cfg.directory}/${cfg.headroom.state}/uv}"
      export HEADROOM_SESSION="''${HEADROOM_SESSION:-${cfg.headroom.session}}"
    '';
  };

  mkPresetShell = preset:
    mkShell {
      name = "dots-${preset.name}";
      env = core.env // preset.env;
      packages = core.packages ++ preset.packages;
      shellHook = core.runtimeHook + preset.shellHook;
    };

  mkComponentShell = name: component:
    mkShell {
      name = "dots-ai-${name}";
      env = core.env // (component.env or {}) // (componentEnv.${name} or {});
      packages = core.packages ++ (component.packages or []);
      shellHook = core.runtimeHook + (componentHook.${name} or "") + (component.shellHook or "");
    };

  shells = builtins.mapAttrs (_: mkPresetShell) presets;
  defaultName = "ai-${cfg.defaultPreset}";
  default = presets.${defaultName} or (throw "Unknown default AI preset '${defaultName}'");

  devShells =
    shells
    // {
      ai = shells.${defaultName};
      "ai-headroom" = mkComponentShell "headroom" context.headroom;
      "ai-hindsight" = mkComponentShell "hindsight" memory.hindsight;
      "ai-mem0" = mkComponentShell "mem0" memory.mem0;
      "ai-nine-router" = mkComponentShell "nine-router" router."nine-router";
      "ai-omniroute" = mkComponentShell "omniroute" router.omniroute;
    };
in {
  inherit devShells;
  inherit (default) env packages shellHook;
  description = "AI Development";
}
