{
  defaultPreset = "hermes-hindsight-headroom-nine-router";
  directory = "ai";
  instance = "default";
  bindAddress = "127.0.0.1";
  portOffset = 0;

  hermes = {
    secrets = "hermes.env";
    state = "hermes";
    gateway = "gateway.json";
  };

  hindsight = let
    version = "0.9.2";
  in {
    inherit version;
    secrets = "hindsight.env";
    image = "ghcr.io/vectorize-io/hindsight:${version}";
    runtime = "podman";

    ports = {
      api = 8888;
      mcp = 9999;
      ui = 8889;
    };

    mode = "local_external";
    bank = "hermes";
    recallBudget = "mid";

    llm = {
      backend = "openrouter";
      baseUrl = "https://openrouter.ai/api/v1";
      model = "openrouter/free";
      reflectModel = "openrouter/free";
    };
  };

  mem0.port = 8888;

  omniroute = {
    secrets = "omniroute.env";
    bindAddress = "127.0.0.1";
    port = 20128;
    state = "omniroute";
    session = "omniroute";
  };

  nineRouter = {
    secrets = "nine-router.env";
    bindAddress = "127.0.0.1";
    port = 20129;
    state = "nine-router";
    session = "nine-router";
  };

  headroom = {
    bindAddress = "127.0.0.1";
    port = 8787;
    state = "headroom";
    session = "headroom";
  };
}
