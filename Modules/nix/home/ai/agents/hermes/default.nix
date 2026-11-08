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
  inherit (lix.attrsets.transformation) mapAttrs;
  inherit (lix.lists.predicates) isIn;
  inherit (lix.filesystem.construction) concatPath;
  inherit (lix.schema.construction) mkSchema;
  inherit (lix.modules.construction) mkConfig mkContext mkMerge mkDefault mkLayer;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.schema.packages) selectedPackages;
  inherit (lix.toolkit) packages;
  inherit (lix.schema.hermes) mkHermes isValidProfileName;
  inherit (lix.types.primitives) str;

  common = lix.toolkit.hermes;
  inherit (common) validator;
  runtime = common.forConfig config.services.hermes-agent;
  # Export the baseline from the declarations so each default has one owner.
  declaredDefaults = declarations:
    mapAttrs (_name: declaration:
      if (declaration._type or null) == "option"
      then declaration.default
      else declaredDefaults declaration)
    declarations;
  defaults = declaredDefaults core.options;
  interface = import ./interface {inherit lix;};

  projects =
    user.paths.home.projects.stem or user.paths.stems.home.projects
    or host.paths.home.projects.stem or host.paths.stems.home.projects
    or (mkSchema {}).paths.stems.home.projects;
  homePath = concatPath {
    root = config.home.homeDirectory;
    stem = projects ++ ["hermes"];
  };

  resolve = defaults:
    mkHermes {
      inherit defaults host user lix;
      inherit (config.home) homeDirectory;
      homePath = cfg.home.path;
    };
  resolved = resolve (defaults
    // {
      enable = isIn ["hermes" "hermes-agent" "hermes-desktop"] (selectedPackages user);
      home = defaults.home // {path = homePath;};
      workingDirectory = cfg.home.path;
      desktop = defaults.desktop // {package = runtime.package.hermesDesktop;};
    });
  upstreamOptions = common.sharedOptions {
    defaultPackage = packages.hermes;
    defaultPackageText = "lix.toolkit.packages.hermes";
    defaultWorkingDirectory = ".";
    defaultWorkingDirectoryText = "\".\" (resolved to the Home Manager home directory)";
  };
  featureArgs = passthru // {inherit cfg common context interface runtime entryBetween resolve validator isValidProfileName;};
  features = map (feature: import feature featureArgs) [./bots ./connection ./kanban ./knowledge ./report ./shared];
  core = {
    inherit defaults;

    options = mergeSafe [
      (interface.options (upstreamOptions
        // {
          settings =
            upstreamOptions.settings
            // {
              default.memory = {
                memory_enabled = true;
                user_profile_enabled = true;
                provider = "";
              };
            };
          restart = upstreamOptions.restart // {default = "always";};
          restartSec = upstreamOptions.restartSec // {default = 5;};
        }))
      {
        enable = mkEnable {
          inherit context;
          condition = false;
        };

        home = {
          path = mkOption {
            description = "State directory containing Hermes configuration, profiles, sessions and memory";
            type = str;
            default = ".hermes";
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
        extra = {
          dependencyGroups = upstreamOptions.extraDependencyGroups // {default = ["messaging"];};
          # Bot screens run on the gateway; NixOS cannot use the in-app installer.
          packages =
            upstreamOptions.extraPackages
            // {
              default = with pkgs; [
                tigervnc
                xfwm4
                xfce4-panel
                xfdesktop
                xfce4-settings
                xfce4-terminal
                dbus
                xauth
                xdpyinfo
                setxkbmap
                xprop
                xset
                xsetroot
                dejavu_fonts
              ];
            };
        };

        desktop = {
          enable = mkEnable {
            description = "Install Hermes Desktop";
            condition = true;
          };
          package = mkOption {
            description = "Hermes Desktop package, following the effective Hermes package by default";
            inherit (options.programs.hermes-agent.desktop.package) type;
            default = packages.hermes.hermesDesktop;
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
