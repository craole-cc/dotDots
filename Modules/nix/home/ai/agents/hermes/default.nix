{
  config,
  options,
  lix,
  user,
  pkgs,
  ...
} @ args: let
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
  inherit (lix.modules.construction) mkConfig mkContext mkMerge mkLayer mkDefault;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.schema.packages) selectedPackages;
  inherit (lix.toolkit) packages;
  inherit (lix.types.combinators) attrsOf;
  inherit (lix.types.primitives) anything str;

  common = lix.toolkit.hermes;
  runtime = common.forConfig config.services.hermes-agent;
  defaults = import ./defaults.nix {inherit config lix;};
  interface = import ./interface {inherit lix;};

  upstreamOptions = common.sharedOptions {
    defaultPackage = packages.hermes;
    defaultPackageText = "lix.toolkit.packages.hermes";
    defaultWorkingDirectory = config.home.homeDirectory;
    defaultWorkingDirectoryText = "config.home.homeDirectory";
  };
  parts =
    attrValues
    (importAllMerged {
      dir = ./.;
      args = args // {inherit cfg common defaults interface runtime;};
      exclude = ["defaults.nix" "interface" "lib"];
    }).value;
  collect = field: mergeSafe (map (part: part.${field} or {}) parts);
  settings = foldl' recursiveUpdate {} (map (part: part.settings or {}) parts);
  activeProfiles = filterAttrs (_name: profile: profile.enable) cfg.profiles;
  #? updates diffs against the pre-resolution baseline. Any option that
  #? participates in resolutions (enable, gateway.multiplex, kanban.profiles,
  #? desktop.*) must NOT be given a concrete default here unless it is also
  #? overridden in a mkDefault layer below. Otherwise updates reports spurious
  #? diffs on every rebuild.
  #
  #? Optional derived concurrency. Uncomment to give multi-profile teams
  #? total = length kanban.profiles (capped at 4) instead of static 1.
  # kanbanConcurrency = {
  #   total = builtins.min 4 (builtins.length (["default"] ++ attrNames activeProfiles));
  #   perProfile = 1;
  # };
in
  mkConfig {
    inherit context defaults;

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
        settings =
          upstreamOptions.settings
          // {
            type = attrsOf anything;
            default = defaults.settings;
          };

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

    resolutions = mkMerge [
      (mkLayer 1000 (
        (removeAttrs defaults ["desktop"])
        // {
          enable =
            isIn ["hermes" "hermes-agent" "hermes-desktop"]
            (selectedPackages user);
          gateway = removeAttrs defaults.gateway ["multiplex"];
          kanban = removeAttrs defaults.kanban ["profiles"];
        }
      ))
      {
        gateway.multiplex = mkDefault (activeProfiles != {});
        kanban.profiles = mkDefault (["default"] ++ attrNames activeProfiles);
        # kanban.concurrency = mkDefault kanbanConcurrency;
        desktop = {
          enable = mkDefault defaults.desktop.enable;
          package = mkDefault runtime.package.hermesDesktop;
        };
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
