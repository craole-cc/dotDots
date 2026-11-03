{lix ? (import ../.. {}).libraries.default}: let
  inherit (lix) lib;
  fixturePackage = name: {
    type = "derivation";
    inherit name;
    outPath = "/nix/store/${name}";
  };
  packages = lib.genAttrs ["kitty" "foot" "warp-terminal"] fixturePackage;
  option = type: default: lib.mkOption {inherit type default;};
  atom = lib.types.nullOr (lib.types.oneOf [lib.types.bool lib.types.int lib.types.float lib.types.str]);
  settingsType = lib.types.attrsOf (lib.types.either atom (lib.types.listOf atom));
  moduleLix =
    lix
    // {
      toolkit = (lix.toolkit or {}) // {inherit packages;};
      filesystem =
        lix.filesystem
        // {
          traversal = lix.filesystem.traversal // {importAllPaths = _: {value = [];};};
        };
      applications =
        lix.applications
        // {
          construction =
            lix.applications.construction
            // {
              mkScriptWrappers = _: map fixturePackage ["feet" "feet-quake" "feet-monitor"];
            };
          generators =
            lix.applications.generators
            // {
              userApplicationConfig = {
                context,
                user,
                extraPackages ? [],
                ...
              }: {
                enable = user.selected;
                package = packages.${context.mod};
                isPrimary = user.selected;
                isPlatformCompatible = true;
                home = {
                  packages = [packages.${context.mod}] ++ extraPackages;
                  sessionVariables = {};
                  shellAliases = {};
                };
              };
            };
        };
      sources =
        lix.sources
        // {
          packages =
            lix.sources.packages
            // {
              pkgOf = {
                inputs,
                input,
                alias,
                ...
              }: let
                package = inputs.${input}.packages.x86_64-linux.default;
              in {
                inherit package;
                exeOf = executable: "${package.outPath}/bin/${executable}";
                description = "Fixture package";
                paths = {
                  inherit (package) outPath;
                  executable = "${package.outPath}/bin/warp";
                };
                alias =
                  if alias == null
                  then null
                  else (fixturePackage alias) // {target = package;};
              };
            };
        };
    };
  evaluate = selected:
    lib.evalModules {
      specialArgs = {
        lix = moduleLix;
        top = "_";
        user = {
          inherit selected;
          packages.terminal = lib.optional selected "warp-terminal";
        };
        pkgs =
          packages
          // {
            stdenv.hostPlatform.system = "x86_64-linux";
            makeDesktopItem = args: fixturePackage args.name;
          };
        paths.store.lib.sh = /tmp;
        style.opacity.terminal = {
          dark = 1.0;
          light = 1.0;
        };
        inputs.warp-terminal.packages.x86_64-linux.default =
          packages.warp-terminal
          // {
            overrideAttrs = _: packages.warp-terminal;
          };
      };
      modules = [
        ../../Modules/nix/home/default.nix
        ../../Modules/nix/home/terminal/core/kitty/default.nix
        ../../Modules/nix/home/terminal/core/foot/default.nix
        ../../Modules/nix/home/terminal/core/warp/default.nix
        {
          options = {
            _.resolved.interface.panels.active = option lib.types.str "none";
            home = {
              packages = option (lib.types.listOf lib.types.package) [];
              sessionVariables = option (lib.types.attrsOf lib.types.str) {};
              shellAliases = option (lib.types.attrsOf lib.types.str) {};
            };
            programs = {
              kitty = {
                enable = option lib.types.bool false;
                package = option (lib.types.nullOr lib.types.package) packages.kitty;
                settings = option settingsType {};
                extraConfig = option lib.types.lines "";
              };
              foot = {
                enable = option lib.types.bool false;
                package = option lib.types.package packages.foot;
                settings = option (lib.types.attrsOf settingsType) {};
                server.enable = option lib.types.bool false;
              };
            };
          };
        }
      ];
    };
  enabledEvaluation = evaluate true;
  enabled = enabledEvaluation.config;
  disabled = (evaluate false).config;
  customised =
    (enabledEvaluation.extendModules {
      specialArgs.style.opacity.terminal = {
        dark = 0.75;
        light = 0.9;
      };
      modules = [
        {
          _.resolved.interface.panels.active = "dms-shell";
          _.resolved.terminal.emulators = {
            kitty.defined = {
              package = fixturePackage "custom-kitty";
              settings.copy_on_select = "primary";
              home.sessionVariables.KITTY_TEST = "configured";
            };
            foot.defined = {
              package = fixturePackage "custom-foot";
              settings.main.font = "custom:size=12";
              server.enable = false;
              extraPackages = [(fixturePackage "foot-extra")];
              home.shellAliases.ft = "feet";
            };
            warp-terminal.defined = {
              package = fixturePackage "custom-warp";
              enableAlias = false;
            };
          };
        }
      ];
    }).config;
  aliases =
    (enabledEvaluation.extendModules {
      modules = [{_.resolved.terminal.emulators.warp-terminal.defined.package = fixturePackage "custom-warp";}];
    }).config;
in
  assert enabled._.defaults.terminal == disabled._.defaults.terminal;
  assert enabled.programs.kitty.enable && enabled.programs.foot.enable;
  assert !disabled.programs.kitty.enable && !disabled.programs.foot.enable;
  assert disabled.home.packages == [];
  assert enabled.programs.foot.server.enable;
  assert lib.length enabled._.resolved.terminal.emulators.foot.defined.home.packages == 5;
  assert enabled._.defaults.terminal.emulators.foot.settings.main.font == "monospace:size=8";
  assert customised.programs.kitty.package.name == "custom-kitty";
  assert customised.programs.kitty.settings.copy_on_select == "primary";
  assert customised.programs.kitty.settings.background_opacity == 0.75;
  assert lib.hasInfix "include dank-theme.conf" customised.programs.kitty.extraConfig;
  assert customised.home.sessionVariables.KITTY_TEST == "configured";
  assert customised.programs.foot.package.name == "custom-foot";
  assert customised.programs.foot.settings.main.font == "custom:size=12";
  assert customised.programs.foot.settings.colors-dark.alpha == 0.75;
  assert customised.programs.foot.settings.colors-light.alpha == 0.9;
  assert !customised.programs.foot.server.enable;
  assert customised.home.shellAliases.ft == "feet";
  assert lib.elem (fixturePackage "foot-extra") customised.home.packages;
  assert lib.elem (fixturePackage "custom-warp") customised.home.packages;
  assert customised._.resolved.terminal.emulators.warp-terminal.defined.alias == null;
  assert customised._.resolved.terminal.emulators.warp-terminal.derived.home.packages == [(fixturePackage "custom-warp")];
  assert aliases._.resolved.terminal.emulators.warp-terminal.defined.alias.target.name == "custom-warp";
  assert !(enabled._.resolved.terminal.emulators.warp-terminal.defined.pkg ? exeOf);
  assert customised._.updates.terminal.emulators.kitty.settings.copy_on_select == "primary";
  assert customised._.defaults.terminal.emulators.kitty.settings.copy_on_select == "clipboard";
  assert customised._.updates.terminal.emulators.foot.settings.main.font == "custom:size=12"; {passed = true;}
