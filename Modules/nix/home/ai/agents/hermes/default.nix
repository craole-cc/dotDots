{
  config,
  pkgs,
  options,
  lix,
  user,
  host ? {},
  entryBetween,
  ...
} @ passthru: let
  dom = "ai";
  sub = "agents";
  mod = "hermes-agent";
  context = mkContext {inherit config dom sub mod;};

  inherit (context) cfg;
  inherit (lix.attrsets.aggregation) intersectAttrs mergeSafe;
  inherit (lix.lists.predicates) isIn;
  inherit (lix.modules.construction) mkConfig mkContext mkMerge mkDefault mkLayer;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.schema.packages) selectedPackages;
  inherit (lix.toolkit) packages;
  inherit (lix.schema.hermes) mkHermes;
  inherit (lix.types.primitives) str;

  common = lix.toolkit.hermes;
  runtime = common.forConfig config.services.hermes-agent;
  defaults = import ./defaults.nix {
    inherit lix;
  };
  interface = import ./interface {inherit lix;};

  resolve = defaults:
    mkHermes {
      inherit defaults host user lix;
      inherit (config.home) homeDirectory;
    };
  resolved = resolve (defaults
    // {
      enable = isIn ["hermes" "hermes-agent" "hermes-desktop"] (selectedPackages user);
      home = defaults.home // {path = "${config.home.homeDirectory}/.hermes";};
      workingDirectory = config.home.homeDirectory;
      desktop = defaults.desktop // {package = runtime.package.hermesDesktop;};
    });
  upstreamOptions = common.sharedOptions {
    defaultPackage = packages.hermes;
    defaultPackageText = "lix.toolkit.packages.hermes";
    defaultWorkingDirectory = defaults.workingDirectory;
    defaultWorkingDirectoryText = "\".\" (resolved to the Home Manager home directory)";
  };
  featureArgs = passthru // {inherit cfg common context interface runtime entryBetween resolve;};
  features = map (feature: import feature featureArgs) [./bots ./connection ./kanban ./report];
  core = {
    inherit defaults;

    options = mergeSafe [
      (interface.options (upstreamOptions
        // {
          settings = upstreamOptions.settings // {default = defaults.settings;};
          restart = upstreamOptions.restart // {default = defaults.restart.when;};
          restartSec = upstreamOptions.restartSec // {default = defaults.restart.seconds;};
        }))
      {
        enable = mkEnable {
          inherit context;
          condition = defaults.enable;
        };

        home = {
          path = mkOption {
            description = "State directory containing Hermes configuration, profiles, sessions and memory";
            type = str;
            default = defaults.home.path;
          };
          file =
            upstreamOptions.hermesHomeFiles
            // {
              description = "Files installed relative to home.path, such as SOUL.md and memories/USER.md; values are strings or paths";
            };
        };
        documents =
          upstreamOptions.documents
          // {
            description = "Workspace files installed relative to an explicitly selected workingDirectory; use home.file for identity and memory files";
          };
        extra.dependencyGroups = upstreamOptions.extraDependencyGroups // {default = defaults.extra.dependencyGroups;};

        desktop = {
          enable = mkEnable {
            description = "Install Hermes Desktop";
            condition = defaults.desktop.enable;
          };
          package = mkOption {
            description = "Hermes Desktop package, following the effective Hermes package by default";
            inherit (options.programs.hermes-agent.desktop.package) type;
            default = defaults.desktop.package;
          };
        };
      }
    ];

    # Per-key baseline definitions preserve siblings when an attrs option is
    # partially overridden. Option defaults alone replace the whole attrset.
    resolutions = mkMerge [
      (mkLayer 1000 (removeAttrs (intersectAttrs defaults resolved) ["desktop" "settings"]))
      {
        settings =
          if resolved.settings == {}
          then mkDefault {}
          else mkLayer 1000 resolved.settings;
        desktop = mkLayer 1000 resolved.desktop;
      }
    ];

    outputs = mkMerge [
      {
        services.${mod} =
          (interface.config upstreamOptions cfg)
          // {
            hermesHome = cfg.home.path;
          };
        programs.${mod} = {
          inherit (cfg) enable desktop;
          inherit (runtime) package;
        };
      }
    ];
  };
  contracts = [core] ++ features;
in
  mkConfig {
    inherit context;
    defaults = mergeSafe (map (contract: contract.defaults or {}) contracts);
    options = mergeSafe (map (contract: contract.options or {}) contracts);
    resolutions = mkMerge (map (contract: contract.resolutions or {}) contracts);
    outputs = mkMerge (map (contract: contract.outputs or {}) contracts);
  }
