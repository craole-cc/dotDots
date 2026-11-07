{
  config,
  lix,
}: let
  inherit (lix.toolkit) packages;
  inherit (lix.filesystem.construction) concat;
  inherit (lix.filesystem.access) readDir;
  inherit (lix.filesystem.predicates) pathExists;
  inherit (lix.attrsets.access) attrNames;
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.attrsets.construction) genAttrs optionalAttrs;
  inherit (lix.attrsets.transformation) mapAttrs;
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

  keyPath = root: stem: concat {inherit root stem;};

  #? A profile receives only its own provider's file, and only if it exists.
  #? openai-codex authenticates through auth.json and finds no file.
  keysFor = provider: filter pathExists [(keyPath dirs.keys "${provider}.env")];

  memory = {
    memory_enabled = true;
    user_profile_enabled = true;
    provider = "";
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

  #? Luna for routing and gathering, sol where mistakes are expensive.
  roster = {
    receptionist = {
      description = "Receive requests, clarify requirements and hand tasks to the planner.";
      settings.model = models.gpt.flash;
      terse.level = "full";
      home.file."SOUL.md" = "Keep replies brief. Record clear Kanban tasks for planner; specialists perform substantive work.";
    };
    researcher = {
      description = "Research questions and provide source-backed findings.";
      settings.model = models.default.flash;
    };
    planner = {
      description = "Plan task graphs, coordinate specialists and synthesise results.";
      settings.model = models.default.smart;
    };
    coder = {
      description = "Implement scoped changes and record evidence for review.";
      settings.model = models.deepseek.flash;
    };
    reviewer = {
      description = "Review changes for correctness and report actionable findings.";
      settings.model = models.deepseek.smart;
    };
  };

  # Adopt the installed roster as well: upstream automatic planning sees every
  # installed profile, so every current candidate must be an admitted worker.
  installed = [
    "accessibility-auditor"
    "api-designer"
    "architect"
    "backend-engineer"
    "code-reviewer"
    "cole-bassed"
    "data-analyst"
    "debugger"
    "dev"
    "devops-engineer"
    "doc-writer"
    "frontend-engineer"
    "glm-analyst"
    "incident-responder"
    "lab"
    "ling-translator"
    "local"
    "performance-optimiser"
    "prompt-engineer"
    "refactorer"
    "research"
    "safe-gateway"
    "security-auditor"
    "sql-expert"
    "test-writer"
    "writing"
  ];

  adopted = genAttrs installed (_: {
    bot.enable = true;
    settings = {inherit memory;};
  });

  starters = mapAttrs (_: profile:
    recursiveUpdate {
      bot.enable = true;
      #? Runtime string paths seed writable auth files; credentials never enter Nix.
      auth.file = keyPath dirs.home "auth.json";
      environment.files = keysFor (profile.settings.model.provider or models.default.provider);
      settings = {
        inherit memory;
        model = models.default;
      };
    }
    profile)
  roster;

  defaults = {
    enable = false;
    package = packages.hermes;
    workingDirectory = dirs.user;
    config.file = null;
    settings = {
      inherit memory;
      model = models.gpt.smart;
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

    #? The main service gets every discovered key file; profiles only get their own.
    environment = {
      variables = {};
      files = let
        #? Discovery: ~/Private/hermes.env plus every *.env in ~/Private/hermes/.
        entries = optionalAttrs (pathExists dirs.keys) (readDir dirs.keys);
        envNames = filter (name: entries.${name} == "regular" && hasSuffix ".env" name) (attrNames entries);
        discoveredKeyFiles =
          filter pathExists [(keyPath (dirOf dirs.keys) "hermes.env")]
          ++ map (keyPath dirs.keys) envNames;
      in
        discoveredKeyFiles;
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

    profiles = adopted // starters;
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
in
  defaults
