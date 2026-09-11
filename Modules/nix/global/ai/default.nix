{
  args,
  core,
  ...
}: let
  inherit (args) lix pkgs;
  inherit (lix.attrsets.transformation) mapAttrs;
  inherit (pkgs) mkShell;

  cfg = args.host.shells.ai or (throw "AI shell configuration is missing from host.shells.ai");
  paths = args.paths;
  aiArgs = args // {inherit cfg paths;};

  agents = import ./agents aiArgs;
  memory = import ./memory aiArgs;
  router = import ./router aiArgs;
  presets = import ./presets (aiArgs // {inherit agents memory router;});

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

  shells = mapAttrs (_: mkPresetShell) presets;
  defaultName = "ai-${cfg.defaultPreset}";
  default = presets.${defaultName} or (throw "Unknown default AI preset '${defaultName}'");

  devShells =
    shells
    // {
      ai = shells.${defaultName};
      "ai-hindsight" = mkComponentShell "hindsight" memory.hindsight;
      "ai-mem0" = mkComponentShell "mem0" memory.mem0;
      "ai-omniroute" = mkComponentShell "omniroute" router.omniroute;
    };
in {
  inherit devShells;
  inherit (default) env packages shellHook;
  description = "AI Development";
}
