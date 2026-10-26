{
  config,
  entryAfter,
  lix,
  inputs,
  paths,
  pkgs,
  style,
  user,
  toolkit,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "interface";
    mod = "wallpaper";
  };
  inherit (context) cfg ctx;
  inherit (lix.attrsets.construction) optionalAttrs;
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.modules.home.paths) mkUserPath;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.types.combinators) enum nullOr;
  inherit (lix.sources.packages) pkgsFrom;

  paths' = let
    wallpapers = {
      main =
        paths.wallpapers.primary or (mkUserPath {
          inherit user;
          home = config.home.homeDirectory;
          dots = paths.local.src;
          path = ["wallpapers"];
          default = "home:Pictures/Wallpapers";
        });
      slideshow = paths'.wallpapers.main;
      folders = [paths'.wallpapers.main];
    };
  in
    recursiveUpdate {inherit wallpapers;} paths;

  tool = let
    resolved = pkgsFrom {
      inherit inputs pkgs;
      sources =
        optionalAttrs cfg.hyprpaper.enable {hyprpaper = null;}
        // optionalAttrs (cfg.enable && (cfg.backend == "auto" || cfg.backend == "swaybg")) {swaybg = null;};
    };
  in {inherit (resolved) packages;};

  args = {
    inherit config entryAfter inputs toolkit lix pkgs style user;
    paths = paths';
    wallpaper = context;
  };
in
  {imports = [(import ./variety args)];}
  // mkConfig {
    inherit context;

    options = {
      engine = mkOption {
        type = nullOr (enum ["variety"]);
        default = user.interface.wallpaper.engine or "variety";
        description = ''
          Wallpaper selection and rotation engine, defaulting to the resolved user interface preference.
          Null leaves selection unmanaged.
        '';
      };
      backend = mkOption {
        type = enum ["auto" "dms" "hyprpaper" "swaybg"];
        default = user.interface.wallpaper.backend or "auto";
        description = ''
          Wallpaper backend, fixed by the controller wrapper. Auto chooses DMS
          when reachable, otherwise a backend for the compositor. Once selected,
          failure is final; the controller never falls through to another backend.
        '';
      };
      enable = mkEnable {
        inherit context;
        condition = with ctx;
          (windowManagers != null) || (desktopEnvironments != null);
      };
      hyprpaper.enable = mkEnable {
        inherit context;
        condition = cfg.enable && ctx.wantsHyprland.condition;
      };
    };

    outputs = {
      home = {
        inherit (tool) packages;
        sessionVariables = {
          WALLPAPER_ENGINE = cfg.engine;
        };
      };
    };
  }
