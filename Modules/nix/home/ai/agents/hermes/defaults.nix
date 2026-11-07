{
  config,
  lix,
}: let
  inherit (lix.toolkit) packages;
  inherit (lix.filesystem.construction) concat;
  inherit (lix.filesystem.access) readDir;
  inherit (lix.filesystem.predicates) pathExists;
  inherit (lix.attrsets.access) attrNames;
  inherit (lix.attrsets.construction) optionalAttrs;
  inherit (lix.lists.transformation) filter;
  inherit (lix.strings.predicates) hasSuffix;

  dirs = {
    user = config.home.homeDirectory;
    home = concat {
      root = dirs.user;
      stem = ".hermes";
    };
    keys = concat {
      root = dirs.user;
      stem = ["Private" "hermes"];
    };
  };

  models = rec {
    default = gpt;
    gpt = {
      flash = {
        provider = "openai-codex";
        default = "gpt-6-luna";
      };
      smart = {
        provider = "openai-codex";
        default = "gpt-6.1-sol";
      };
    };
    deepseek = {
      flash = {
        provider = "deepseek";
        default = "deepseek-flash";
      };
      smart = {
        provider = "deepseek";
        default = "deepseek-v4-pro";
      };
    };
  };

  defaults = {
    enable = false;
    package = packages.hermes;
    workingDirectory = dirs.user;
    config.file = null;
    settings = {
      inherit memory;
      model = models.default.smart;
    };
    documents = {};
    mcpServers = {};

    home = {
      path = dirs.home;
      file = {};
    };

    auth = {
      file = null;
      overwrite = false;
    };

    environment = {
      variables = {};
      files = let
        inherit (dirs) keys;
        mk = {root ? keys}: stem: concat {inherit root stem;};
        entries = optionalAttrs (pathExists keys) (readDir keys);
      in
        (filter pathExists [(mk {root = dirOf keys;} "hermes.env")])
        ++ map (mk {}) (filter (
          name: entries.${name} == "regular" && hasSuffix ".env" name
        ) (attrNames entries));
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

    profiles = import ./bots/roster.nix {
      inherit config lix models memory;
      homePath = dirs.home;
    };
    strictProfileValidation = false;
    desktop = {
      enable = true;
      package = defaults.package.hermesDesktop;
    };

    kanban = {
      enable = true;
      profiles = ["default"];
      orchestrator = "planner";
      defaultAssignee = "planner";
      concurrency = {
        total = 1;
        perProfile = 1;
      };
      decomposition = {
        enable = false;
        model = {
          inherit (models.default.smart) provider;
          model = models.default.smart.default;
        };
      };
    };
  };
  memory = {
    memory_enabled = true;
    user_profile_enabled = true;
    provider = "";
  };
in
  defaults
