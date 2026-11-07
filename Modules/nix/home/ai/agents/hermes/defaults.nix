{lix}: let
  inherit (lix.toolkit) packages;
  defaults = {
    enable = false;
    package = packages.hermes;
    workingDirectory = ".";
    config.file = null;
    settings = {
      memory = {
        memory_enabled = true;
        user_profile_enabled = true;
        provider = "";
      };
    };
    documents = {};
    mcpServers = {};

    home = {
      path = ".hermes";
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

    desktop = {
      enable = true;
      package = defaults.package.hermesDesktop;
    };
  };
in
  defaults
