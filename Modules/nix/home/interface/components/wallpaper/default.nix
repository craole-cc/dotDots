{
  config,
  entryAfter,
  lix,
  inputs,
  paths,
  pkgs,
  style,
  user,
  fonts,
  ...
} @ passthru: let
  context = mkContext {
    inherit config;
    dom = "interface";
    mod = "wallpaper";
  };
  inherit (context) cfg ctx;
  inherit (lix.attrsets.access) attrNames;
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.attrsets.transformation) mapAttrs;
  inherit (lix.lists.access) findFirst;
  inherit (lix.lists.construction) optional optionals;
  inherit (lix.modules.home.paths) mkUserPath;
  inherit (lix.modules.construction) mkConfig mkContext mkIf mkMerge;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.types.combinators) enum nullOr;
  inherit (lix.types.primitives) package;
  inherit (lix.toolkit) packages;

  args = recursiveUpdate passthru {
    paths = let
      mainWallpaper =
        paths.wallpapers.primary or (mkUserPath {
          inherit user;
          home = config.home.homeDirectory;
          dots = paths.local.src;
          path = ["wallpapers"];
          default = "home:Pictures/Wallpapers";
        });
      wallpapers = {
        main = mainWallpaper;
        slideshow = mainWallpaper;
        folders = [mainWallpaper];
      };
    in
      recursiveUpdate {inherit wallpapers;} paths;
    wallpaper = context;
  };

  engines = {
    custom = {
      condition = false;
      enable = cfg.engines.active == "custom";
      package = null;
      packageType = nullOr package;
    };

    variety = let
      name = "variety";
      condition = (ctx.windowManagers != null) || (ctx.desktopEnvironments != null);
    in {
      inherit condition;
      package = packages.${name};
      enable = condition && cfg.engines.active == name;
      options = variety.options // {
        enable = mkEnable {
          inherit context;
          condition = engines.${name}.enable;
        };
      };
    };
  };

  backends = {
    custom = {
      condition = false;
      enable = cfg.backends.active == "custom";
      package = null;
      packageType = nullOr package;
    };

    dms = let
      name = "dms-shell";
      ctx = context.resolved.cfg.interface.panels.${name}.explicit;
      condition = ctx.enable;
    in {
      inherit ctx condition;
      inherit (ctx) package;
      enable = condition && cfg.backends.active == "dms";
    };

    hyprpaper = let
      name = "hyprpaper";
      inherit (ctx.wantsHyprland) condition;
    in {
      inherit condition;
      package = packages.${name};
      enable = condition && cfg.backends.active == name;
    };

    swaybg = let
      name = "swaybg";
      condition = !ctx.wantsHyprland.condition && ctx.isWayland;
    in {
      inherit condition;
      package = packages.${name};
      enable = condition && cfg.backends.active == name;
    };
  };
  variety = import ./variety args;
in
  mkConfig {
    inherit context;

    options = {
      enable = mkEnable {
        inherit context;
        condition = with ctx;
          (windowManagers != null) || (desktopEnvironments != null);
      };

      engines =
        (mapAttrs (name: engine:
          engine.options or {
            enable = mkEnable {
              inherit context;
              condition = engine.enable;
            };
            package = mkOption {
              description = "Package to use for the ${name} wallpaper engine.";
              default = engine.package;
              type = engine.packageType or package;
            };
          })
        engines)
        // {
          preferred = mkOption {
            description = "Preferred wallpaper engine: null or auto selects an eligible engine, none disables selection, and custom uses the override package.";
            default = null;
            type = nullOr (enum (["auto" "none"] ++ attrNames engines));
          };

          active = mkOption {
            description = "Resolved wallpaper engine. Auto chooses Variety; none resolves to null, and custom uses engines.custom.package.";
            default = let
              inherit (cfg.engines) preferred custom;
            in
              if preferred == null || preferred == "auto"
              then findFirst (name: engines.${name}.condition) null (attrNames engines)
              else if preferred == "none"
              then null
              else if preferred == "custom" && custom.package == null
              then throw "The custom wallpaper engine requires engines.custom.package."
              else preferred;
            type = nullOr (enum (attrNames engines));
          };
        };

      backends =
        (
          mapAttrs (name: backend: {
            enable = mkEnable {
              inherit context;
              condition = backend.enable;
            };
            package = mkOption {
              description = "Package to use for ${name}";
              default = backend.package;
              type = backend.packageType or package;
            };
          })
          backends
        )
        // {
          preferred = mkOption {
            description = "Preferred wallpaper backend: null or auto selects an eligible backend, none disables it, and custom uses the override package.";
            default = null;
            type = nullOr (enum (["auto" "none"] ++ attrNames backends));
          };

          active = mkOption {
            description = ''
              Resolved wallpaper backend. Auto chooses DMS when enabled, otherwise
              Hyprpaper for Hyprland or swaybg for other compositors.
              None resolves to null; custom uses backends.custom.package.
            '';
            default = let
              inherit (cfg.backends) preferred custom;
            in
              if (preferred == null || preferred == "auto")
              then findFirst (name: backends.${name}.condition) null (attrNames backends)
              else if preferred == "none"
              then null
              else if preferred == "custom" && custom.package == null
              then throw "The custom wallpaper backend requires backends.custom.package."
              else preferred;
            type = nullOr (enum (attrNames backends));
          };
        };
    };

    outputs = mkMerge [
      (mkIf cfg.engines.variety.enable {
        home = removeAttrs variety.outputs.home ["packages"];
      })
      {
        home = {
          packages =
            optionals cfg.engines.variety.enable variety.outputs.home.packages
            ++ optional (cfg.backends.custom.enable && cfg.backends.custom.package != null) cfg.backends.custom.package
            ++ optional (cfg.engines.custom.enable && cfg.engines.custom.package != null) cfg.engines.custom.package;
          sessionVariables = {
            WALLPAPER_ENGINE = cfg.engines.active;
          };
        };
      }
    ];
  }
