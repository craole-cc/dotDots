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
  inherit (lix.modules.home.paths) mkUserPath;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.types.combinators) enum nullOr;
  inherit (lix.types.primitives) package;
  # inherit (lix.sources.packages) pkgsFrom;

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

  # tool = let
  #   resolved = pkgsFrom {
  #     inherit inputs pkgs;
  #     sources =
  #       optionalAttrs cfg.hyprpaper.enable {hyprpaper = null;}
  #       // optionalAttrs (cfg.enable && (cfg.backend == "auto" || cfg.backend == "swaybg")) {swaybg = null;};
  #   };
  # in {inherit (resolved) packages;};

  args =
    passthru
    // {
      # inherit config entryAfter inputs toolkit lix pkgs style user;
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

      backends = {
        /**
          TODO Fix active
        nix-repl> config.home-manager.users.craole._.resolved.interface.wallpaper.explicit.backends
        {
          active = «error: expected a list but found a set: { _type = "option-type"; check = «thunk»; deprecationMessage = null; description = «thunk»; descriptionClass = «thunk»; emptyValue = «thunk»; functor = «thunk»; getSubModules = null; getSubOptions = «thunk»; merge = «lambda mergeEqualOption @ /nix/store/88r5p1wfmmhapm6cjhi20l7ip3h907kj-source/lib/options.nix:501:5»; «4 attributes elided» }»;
          dms = { ... };
          hyprpaper = { ... };
          swaybg = { ... };
        }

        nix-repl> config.home-manager.users.craole._.resolved.interface.wallpaper.explicit.backends.dms
        {
          enable = true;
          package = «derivation /nix/store/f17x2cfhksq6ik9v8d9mkadn4z8zjl24-dms-shell-1.7-beta+date=2026-10-20_d04eae4.drv»;
        }
        */
        active = mkOption {
          description = ''
            Wallpaper backend, fixed by the controller wrapper. Auto chooses DMS
            when reachable, otherwise a backend for the compositor. Once selected,
            failure is final; the controller never falls through to another backend.
          '';
          default = user.interface.wallpaper.backend or "auto";
          type = enum ["auto" "dms"] ++ (attrNames (removeAttrs cfg.backends ["active"]));
          # TODO: We should show the complete record of the active. HOW?
        };

        dms = let
          ctx = context.resolved.cfg.interface.panels.dms-shell.explicit;
        in {
          enable = mkEnable {
            inherit context;
            condition = ctx.enable;
            # condition = false;
          };
          package = mkOption {
            description = "Package to use for dms";
            default = ctx.package;
            # default = toolkit.packages.dms-shell;
            # type = package;
          };
        };

        hyprpaper = {
          enable = mkEnable {
            inherit context;
            condition = cfg.enable && ctx.wantsHyprland.condition;
          };
          package = mkOption {
            description = "Package to use for hyprpaper";
            default = toolkit.packages.hyprpaper;
            type = package;
          };
        };

        swaybg = {
          enable = mkEnable {
            inherit context;
            condition = cfg.enable && ctx.isWayland;
          };
          package = mkOption {
            description = "Package to use for swaybg";
            default = toolkit.packages.swaybg;
            type = package;
          };
        };
      };
    };

    outputs = {
      home = {
        # inherit (tool) packages;
        sessionVariables = {
          WALLPAPER_ENGINE = cfg.engine;
        };
      };
    };
  }
