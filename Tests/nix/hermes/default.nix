{
  flake,
  exportFixture ? false,
}: let
  inherit (flake.lib) lix;
  inherit (lix.lists.predicates) all any;
  inherit (lix.lists.selection) filter;
  inherit (lix.strings.predicates) hasInfix;

  pkgs = import flake.inputs.nixPackages {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
  toolkit = lix.sources.toolkit.mkToolkit {
    inherit pkgs;
    inputs = lix.sources.inputs.normalize {inputs = flake.inputs;};
  };
  toolkitAliases = lix.sources.toolkit.mkAliases {
    binaries.hermes = toolkit.records.hermes.paths.executable;
    aliases = lix.sources.toolkit.registry.sources.entries.hermes.aliases;
  };
  homeWith = toolkit: extra:
    (flake.inputs.nixHomeManager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {
        lix = lix // {inherit toolkit;};
        user.packages.ai-agent = ["hermes"];
        user.applications.allowed = ["hermes"];
      };
      modules = [
        flake.inputs.hermes.homeManagerModules.default
        ../../../Modules/nix/home/ai/agents/hermes
        ({lib, ...}: {
          options._ = {
            outputs = lib.mkOption {
              type = lib.types.attrsOf lib.types.anything;
              default = {};
            };
            defaults = lib.mkOption {
              type = lib.types.attrsOf lib.types.anything;
              default = {};
            };
          };
          config = {
            home = {
              username = "hermes-test";
              homeDirectory = "/tmp/hermes-module-check";
              stateVersion = "26.05";
            };
            _.resolved.ai.agents.hermes-agent.explicit = extra;
          };
        })
      ];
    }).config;
  home = homeWith toolkit;
  failures = evaluated: map (entry: entry.message) (filter (entry: !entry.assertion) evaluated.assertions);
  rejects = extra: !(builtins.tryEval (builtins.deepSeq (home extra).assertions true)).success;
  baseline = home {};
  alternatePackage = toolkit.packages.hermes.overrideAttrs (_previous: {pname = "hermes-toolkit-test";});
  customisedToolkit = toolkit // {packages = toolkit.packages // {hermes = alternatePackage;};};
  toolkitOverride = homeWith customisedToolkit {};
  serviceOverride = home {package = alternatePackage;};
  desktopPackage = toolkit.packages.hermes.hermesDesktop.overrideAttrs (_previous: {pname = "hermes-desktop-test";});
  desktopOverride = home {desktop.package = desktopPackage;};
  grouped = home {
    home = {
      path = "/tmp/grouped-hermes";
      file."SOUL.md" = "Main identity";
    };
    auth = {
      file = "/run/secrets/main-auth.json";
      overwrite = true;
    };
    extra = {
      args = ["--verbose"];
      packages = [pkgs.hello];
      plugins = [pkgs.hello];
      pythonPackages = [];
      dependencyGroups = ["messaging"];
    };
    environment = {
      variables.HERMES_TEST = "configured";
      files = ["/run/secrets/grouped.env"];
    };
    backend.extra.args = ["--no-browser"];
    restart = {
      when = "on-failure";
      seconds = 7;
    };
    profiles.worker = {
      home.file."SOUL.md" = "Worker identity";
      environment.variables.HERMES_WORKER = "configured";
      environment.files = ["/run/secrets/worker.env"];
      auth = {
        file = "/run/secrets/worker-auth.json";
        overwrite = true;
      };
      extra.plugins = [pkgs.hello];
    };
  };
  configuration = builtins.toFile "hermes-test.yaml" "model:\n  default: fixture-model\n";
  fileConfigured = home {config.file = configuration;};
  declaration = {
    gateway.enable = true;
    extra.dependencyGroups = ["messaging"];
    environment.files = ["/run/secrets/main.env"];
    settings.example.preserved = true;
    profiles = {
      intake = {
        description = "Collect requirements and route work.";
        bot = {
          enable = true;
          title = "Reception";
        };
        settings.model = {
          provider = "ollama";
          default = "qwen3:4b-instruct";
          base_url = "http://127.0.0.1:11434/v1";
        };
        environment.files = ["/run/secrets/intake.env"];
      };
      planner = {
        settings.model = {
          provider = "custom";
          default = "planner-model";
        };
      };
      reviewer = {
        settings.model = {
          provider = "custom";
          default = "review-model";
        };
      };
      parked.enable = false;
    };
    gateway.routes = [
      {
        platform = "telegram";
        profile = "intake";
        chat_id = "123";
      }
    ];
    kanban = {
      enable = true;
      profiles = ["planner" "reviewer"];
      orchestrator = "planner";
      defaultAssignee = "planner";
      decomposition = {
        enable = true;
        model = {
          provider = "custom";
          model = "planner-model";
        };
      };
    };
  };
  team = home declaration;
  activation = team.home.activation.hermesProfiles;
  settings = team.services.hermes-agent.settings;
  withChange = change: lix.attrsets.aggregation.recursiveUpdate declaration change;
  bots = import ../../../Modules/nix/home/ai/agents/hermes/bots {
    lix = lix // {toolkit.write.bin = name: text: {inherit name text;};};
    cfg = team._.resolved.ai.agents.hermes-agent.explicit;
    runtime.binaries.hermesProfile = "/test/hermes --profile";
  };
in
  if exportFixture
  then {
    source = toolkit.records.hermes.paths.outPath;
    python = (toolkit.hermes.forConfig team.services.hermes-agent).package.hermesVenv.outPath;
    settings = team.services.hermes-agent.settings;
    defaultSettings =
      (home {
        profiles.worker = {};
        kanban.enable = true;
      }).services.hermes-agent.settings;
    profiles = lix.attrsets.transformation.mapAttrs (name: profile: {
      inherit (profile) settings;
      metadata = bots.metadata name profile;
    }) (lix.attrsets.transformation.filterAttrs (_name: profile: profile.enable) team._.resolved.ai.agents.hermes-agent.explicit.profiles);
  }
  else {
    flatOptions =
      !(baseline._.resolved.ai.agents.hermes-agent.explicit ? services)
      && baseline._.resolved.ai.agents.hermes-agent.explicit.package == toolkit.packages.hermes;
    flatGateway = baseline._.resolved.ai.agents.hermes-agent.explicit.gateway.enable;
    groupedHome =
      grouped.services.hermes-agent.hermesHome
      == "/tmp/grouped-hermes"
      && grouped.services.hermes-agent.hermesHomeFiles."SOUL.md" == "Main identity";
    groupedAuth =
      grouped.services.hermes-agent.authFile
      == "/run/secrets/main-auth.json"
      && grouped.services.hermes-agent.authFileForceOverwrite;
    groupedExtra =
      grouped.services.hermes-agent.extraArgs
      == ["--verbose"]
      && grouped.services.hermes-agent.extraPackages == [pkgs.hello]
      && grouped.services.hermes-agent.extraPlugins == [pkgs.hello]
      && grouped.services.hermes-agent.extraPythonPackages == []
      && grouped.services.hermes-agent.extraDependencyGroups == ["messaging"];
    groupedEnvironment =
      grouped.services.hermes-agent.environment.HERMES_TEST
      == "configured"
      && grouped.services.hermes-agent.environmentFiles == ["/run/secrets/grouped.env"];
    groupedConfig =
      fileConfigured.services.hermes-agent.configFile
      == configuration
      && baseline._.resolved.ai.agents.hermes-agent.explicit.config.file == null;
    profileEnvironment =
      hasInfix "/run/secrets/worker.env" grouped.home.activation.hermesProfiles.data
      && !(grouped._.resolved.ai.agents.hermes-agent.explicit.profiles.worker ? environmentFiles);
    groupedBackend = grouped.services.hermes-agent.backend.extraArgs == ["--no-browser"];
    restartDefaults =
      baseline._.resolved.ai.agents.hermes-agent.explicit.restart
      == {
        when = "always";
        seconds = 5;
      };
    groupedRestart =
      grouped.services.hermes-agent.restart
      == "on-failure"
      && grouped.services.hermes-agent.restartSec == 7;
    groupedProfile =
      hasInfix "/tmp/grouped-hermes/profiles/worker/SOUL.md" grouped.home.activation.hermesProfiles.data
      && hasInfix "/run/secrets/worker-auth.json" grouped.home.activation.hermesProfiles.data
      && failures grouped == [];
    groupedNames = let
      cfg = grouped._.resolved.ai.agents.hermes-agent.explicit;
    in
      !(cfg ? hermesHome)
      && !(cfg ? hermesHomeFiles)
      && !(cfg ? authFile)
      && !(cfg ? authFileForceOverwrite)
      && !(cfg ? extraArgs)
      && !(cfg ? extraDependencyGroups)
      && !(cfg ? extraPackages)
      && !(cfg ? extraPlugins)
      && !(cfg ? extraPythonPackages)
      && !(cfg ? environmentFiles)
      && !(cfg ? configFile)
      && !(cfg ? restartSec)
      && !(cfg.backend ? extraArgs)
      && !(cfg.profiles.worker ? hermesHomeFiles)
      && !(cfg.profiles.worker ? authFile)
      && !(cfg.profiles.worker ? extraPlugins);
    toolkitPackage = baseline.services.hermes-agent.package == toolkit.packages.hermes;
    toolkitSource = toolkit.records.hermes.paths.outPath == flake.inputs.hermes.outPath;
    toolkitExecutable =
      lix.sources.toolkit.registry.sources.entries.hermes.exe
      == "hermes"
      && toolkit.records.hermes.command == "hermes";
    toolkitAlias = hasInfix "/bin/hermes --tui" toolkitAliases.hermes-tui;
    preparedToolkitPackage =
      toolkit.packages.hermes
      == flake.inputs.hermes.packages.x86_64-linux.default.override {
        extraDependencyGroups = ["messaging"];
      };
    profileAlias = toolkitAliases.hermesProfile == "${toolkit.packages.hermes}/bin/hermes --profile";
    profilesAlias = toolkitAliases.hermesProfiles == "${toolkit.packages.hermes}/bin/hermes profile";
    configuredAliases = let
      runtime = toolkit.hermes.forConfig serviceOverride.services.hermes-agent;
    in
      runtime.package
      == serviceOverride.programs.hermes-agent.package
      && runtime.binaries.hermesProfile == "${runtime.package}/bin/hermes --profile";
    cliDependencies = baseline.programs.hermes-agent.package == toolkit.hermes.effectivePackage baseline.services.hermes-agent;
    toolkitOverride = toolkitOverride.services.hermes-agent.package == alternatePackage;
    serviceOverride =
      serviceOverride.services.hermes-agent.package
      == alternatePackage
      && serviceOverride.programs.hermes-agent.package == toolkit.hermes.effectivePackage serviceOverride.services.hermes-agent;
    desktopOverride = desktopOverride.programs.hermes-agent.desktop.package == desktopPackage;
    unifiedPrograms = let
      cfg = baseline._.resolved.ai.agents.hermes-agent.explicit;
    in
      !(cfg ? programs)
      && !(baseline._.defaults.ai.agents.hermes-agent ? programs)
      && cfg.enable == baseline.programs.hermes-agent.enable;
    defaults =
      !baseline._.defaults.ai.agents.hermes-agent.enable
      && baseline._.defaults.ai.agents.hermes-agent.package == toolkit.packages.hermes;
    disabled = let
      configured = home {enable = false;};
    in
      !configured.services.hermes-agent.enable
      && !configured.programs.hermes-agent.enable
      && !configured.programs.hermes-agent.desktop.enable;
    baseline =
      baseline.services.hermes-agent.gateway.enable
      && baseline.services.hermes-agent.settings == (import ../../../Modules/nix/home/ai/agents/hermes/settings.nix {})
      && !(baseline.home.activation ? hermesProfiles);
    completeModuleDefaults = let
      defaults = baseline._.defaults.ai.agents.hermes-agent;
      upstream = toolkit.hermes.sharedOptions {
        defaultPackage = toolkit.packages.hermes;
        defaultPackageText = "toolkit";
        defaultWorkingDirectory = baseline.home.homeDirectory;
        defaultWorkingDirectoryText = "home.homeDirectory";
      };
      interface = import ../../../Modules/nix/home/ai/agents/hermes/interface.nix {inherit lix;};
    in
      builtins.attrNames (interface.config upstream defaults) == builtins.attrNames upstream;
    neutralProfileDefaults =
      !team._.defaults.ai.agents.hermes-agent.gateway.multiplex
      && team._.defaults.ai.agents.hermes-agent.kanban.profiles == ["default"];
    defaultPrograms =
      baseline._.defaults.ai.agents.hermes-agent.package
      == baseline.programs.hermes-agent.package
      && baseline._.defaults.ai.agents.hermes-agent.desktop.package == baseline.programs.hermes-agent.desktop.package;
    headless = let
      configured = home {
        desktop.enable = false;
      };
    in
      configured.services.hermes-agent.enable && configured.programs.hermes-agent.enable && !configured.programs.hermes-agent.desktop.enable;
    memoryDefaults =
      baseline._.defaults.ai.agents.hermes-agent.settings.memory
      == {
        memory_enabled = true;
        user_profile_enabled = true;
        provider = "";
      };
    memoryOverride = let
      configured = home {settings.memory.memory_enabled = false;};
    in
      !configured.services.hermes-agent.settings.memory.memory_enabled
      && configured.services.hermes-agent.settings.memory.user_profile_enabled;
    noDefaultModel = !(baseline.services.hermes-agent.settings ? model);
    team = failures team == [];
    routes =
      settings.multiplex_profiles
      && settings.profile_routes
      == [
        {
          platform = "telegram";
          profile = "intake";
          chat_id = "123";
        }
      ];
    defaultAssignee =
      (home {
        profiles.worker = {};
        kanban.enable = true;
      }).services.hermes-agent.settings.kanban.default_assignee
      == "default";
    dispatch =
      settings.kanban.dispatch_profiles
      == ["planner" "reviewer"]
      && settings.kanban.orchestrator_profile == "planner"
      && settings.kanban.default_assignee == "planner"
      && settings.kanban.max_in_progress == 1
      && settings.kanban.max_in_progress_per_profile == 1
      && settings.kanban.auto_decompose
      && settings.auxiliary.kanban_decomposer.model == "planner-model";
    rawSettings = settings.example.preserved;
    profileActivation =
      activation.after
      == ["hermesAgentSetup"]
      && activation.before == ["reloadSystemd"]
      && all (name: hasInfix "/profiles/${name}/config.yaml" activation.data) ["intake" "planner" "reviewer"]
      && !(hasInfix "/profiles/parked/" activation.data);
    credentialIsolation =
      hasInfix "/run/secrets/intake.env" activation.data
      && !(hasInfix "/run/secrets/main.env" activation.data);
    botLauncher = any (package:
      package.name
      == "hermes-bot-intake"
      && hasInfix "--profile" package.text
      && hasInfix "intake" package.text
      && hasInfix ''chat -c "Bot Chat" --create-if-missing "$@"'' package.text)
    bots.outputs.home.packages;
    gatewayReload =
      all (trigger: trigger.drvPath != "") team.systemd.user.services.hermes-agent.Unit.X-Restart-Triggers
      && team.systemd.user.services.hermes-agent.Unit.X-Restart-Triggers != [];
    activationDerivation = team.home.activationPackage.drvPath != "";
    customHome =
      hasInfix "/tmp/custom-hermes/profiles/intake/config.yaml"
      (home (withChange {
        home.path = "/tmp/custom-hermes";
      })).home.activation.hermesProfiles.data;
    botMetadata = bots.metadata "intake" declaration.profiles.intake == {ui_meta.hermes-bots.title = "Reception";};
    disabledBot = bots.metadata "plain" {bot.enable = false;} == {ui_meta.hermes-bots = null;};
    defaultRoster =
      (home {
        profiles.worker = {};
        kanban.enable = true;
      }).services.hermes-agent.settings.kanban.dispatch_profiles
      == ["default" "worker"];
    pausedDispatch =
      failures (home (withChange {kanban.profiles = [];}))
      == []
      && (home (withChange {kanban.profiles = [];})).services.hermes-agent.settings.kanban.dispatch_profiles == [];
    unknownRoute = rejects (withChange {gateway.routes = [{profile = "missing";}];});
    disabledRoute = rejects (withChange {gateway.routes = [{profile = "parked";}];});
    emptySender = rejects (withChange {
      gateway.routes = [
        {
          profile = "intake";
          user_id = " ";
        }
      ];
    });
    missingMultiplexer = rejects (withChange {gateway.multiplex = false;});
    invalidWorker = rejects (withChange {kanban.profiles = ["missing"];});
    excludedAssignee = rejects (withChange {kanban.profiles = ["reviewer"];});
    invalidConcurrency = rejects (withChange {kanban.concurrency.total = 0;});
    missingGateway = rejects (withChange {gateway.enable = false;});
    invalidProfileName = rejects (withChange {profiles."../escape" = {};});
    reservedDefault = rejects (withChange {profiles.default = {};});
    implicitWorkspace = rejects (withChange {profiles.intake.documents."AGENTS.md" = "Public instructions";});
  }
