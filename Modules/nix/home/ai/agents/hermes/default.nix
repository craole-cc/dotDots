{
  config,
  pkgs,
  options,
  lix,
  user,
  entryBetween,
  ...
} @ passthru: let
  dom = "ai";
  sub = "agents";
  mod = "hermes-agent";
  context = mkContext {inherit config dom sub mod;};

  inherit (context) cfg;
  inherit (lix.attrsets.access) attrNames attrValues;
  inherit (lix.attrsets.aggregation) mergeSafe recursiveUpdate;
  inherit (lix.attrsets.transformation) filterAttrs;
  inherit (lix.filesystem.traversal) importAllMerged;
  inherit (lix.lists.aggregation) foldl';
  inherit (lix.lists.predicates) isIn;
  inherit (lix.modules.construction) mkConfig mkContext mkMerge mkDefault mkLayer;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.schema.packages) selectedPackages;
  inherit (lix.toolkit) packages;
  inherit (lix.types.primitives) str;

  common = lix.toolkit.hermes;
  runtime = common.forConfig config.services.hermes-agent;
  defaults = import ./defaults.nix {
    inherit config lix;
    inherit (modules) bots;
  };
  interface = import ./interface {inherit lix;};

  upstreamOptions = common.sharedOptions {
    defaultPackage = packages.hermes;
    defaultPackageText = "lix.toolkit.packages.hermes";
    defaultWorkingDirectory = config.home.homeDirectory;
    defaultWorkingDirectoryText = "config.home.homeDirectory";
  };
  args = passthru // {inherit cfg common context defaults interface runtime entryBetween;};
  modules =
    (importAllMerged {
      dir = ./.;
      inherit args;
      exclude = ["defaults.nix" "interface" "lib"];
    }).value;
  parts = attrValues modules;
  collect = field: mergeSafe (map (part: part.${field} or {}) parts);
  settings = foldl' recursiveUpdate {} (map (part: part.settings or {}) parts);
  activeProfiles = filterAttrs (_name: profile: profile.enable) cfg.profiles;
in
  mkConfig {
    inherit context;
    defaults = defaults // collect "baseline";

    options = interface.declareDefaults defaults (mergeSafe [
      (interface.options upstreamOptions)
      (collect "options")
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
    ]);

    # Per-key baseline definitions preserve siblings when an attrs option is
    # partially overridden. Option defaults alone replace the whole attrset.
    resolutions = mkMerge [
      (mkLayer 1000 ((removeAttrs defaults ["enable" "desktop"])
        // {
          gateway = removeAttrs defaults.gateway ["multiplex"];
          kanban = removeAttrs defaults.kanban ["profiles"];
        }))
      {
        enable = mkDefault (isIn ["hermes" "hermes-agent" "hermes-desktop"] (selectedPackages user));
        gateway.multiplex = mkDefault (activeProfiles != {});
        kanban.profiles = mkDefault (["default"] ++ attrNames activeProfiles);
        desktop.package = mkDefault runtime.package.hermesDesktop;
      }
    ];

    outputs = mkMerge [
      {
        services.${mod} =
          (interface.config upstreamOptions cfg)
          // {
            hermesHome = cfg.home.path;
            gateway = {inherit (cfg.gateway) enable;};
            settings = recursiveUpdate cfg.settings settings;
          };
        programs.${mod} = {
          inherit (cfg) enable desktop;
          inherit (runtime) package;
        };
      }
      (mkMerge (map (part: part.outputs or {}) parts))
    ];
  }
