{
  config,
  lix,
}: let
  inherit (lix.toolkit) packages;
  defaults = {
    enable = false;
    package = packages.hermes;
    workingDirectory = config.home.homeDirectory;
    config.file = null;
    settings = import ./settings {};
    documents = {};
    mcpServers = {};
    home = {
      path = "${config.home.homeDirectory}/.hermes";
      file = {};
    };
    auth = {
      file = null;
      overwrite = false;
    };
    environment = {
      variables = {};
      files = [];
    };
    extra = {
      args = [];
      dependencyGroups = ["messaging"];
      packages = [];
      plugins = [];
      pythonPackages = [];
    };
    restart = {
      when = "always";
      seconds = 5;
    };
    backend = {
      mode = "none";
      host = "127.0.0.1";
      port = 9119;
      interfaceName = null;
      sessionTokenFile = null;
      waitFor = null;
      waitTimeout = 120;
      extra.args = [];
    };
    gateway = {
      enable = true;
      multiplex = false;
      routes = [];
    };
    profiles = {};
    desktop = {
      enable = true;
      package = defaults.package.hermesDesktop;
    };
    kanban = {
      enable = false;
      profiles = ["default"];
      orchestrator = null;
      defaultAssignee = null;
      concurrency = {
        total = 1;
        perProfile = 1;
      };
      decomposition = {
        enable = false;
        model = {};
      };
    };
  };
in
  defaults
