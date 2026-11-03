{lix ? (import ../.. {}).libraries.default}: let
  inherit (lix) lib;
  package = {
    type = "derivation";
    name = "ghostty-fixture";
    outPath = "/nix/store/ghostty-fixture";
  };
  testLix =
    lix
    // {
      toolkit = (lix.toolkit or {}) // {packages.ghostty = package;};
      filesystem =
        lix.filesystem
        // {
          traversal =
            lix.filesystem.traversal
            // {
              importAllPaths = _: {value = [];};
            };
        };
      applications =
        lix.applications
        // {
          generators =
            lix.applications.generators
            // {
              userApplicationConfig = {user, ...}: {
                enable = user.selected;
                inherit package;
                programs.ghostty.enable = true;
                home = {};
              };
            };
        };
    };
  evaluate = selected: override:
    lib.evalModules {
      specialArgs = {
        lix = testLix;
        top = "_";
        user = {inherit selected;};
        pkgs.ghostty = package;
        style.opacity.terminal.dark = 1.0;
      };
      modules =
        [
          ../../Modules/nix/home/default.nix
          ../../Modules/nix/home/terminal/core/ghostty/default.nix
          {
            options._.resolved.interface.panels.active = lib.mkOption {
              type = lib.types.str;
              default = "none";
            };
            options.xdg.configHome = lib.mkOption {
              type = lib.types.str;
              default = "/tmp/ghostty-test";
            };
            options.programs.ghostty = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = false;
              };
              package = lib.mkOption {
                type = lib.types.package;
                default = package;
              };
              settings = lib.mkOption {
                type = lib.types.attrsOf lib.types.anything;
                default = {};
              };
            };
            options.home = {
              packages = lib.mkOption {
                type = lib.types.listOf lib.types.package;
                default = [];
              };
              sessionVariables = lib.mkOption {
                type = lib.types.attrsOf lib.types.str;
                default = {};
              };
              shellAliases = lib.mkOption {
                type = lib.types.attrsOf lib.types.str;
                default = {};
              };
            };
            options._.resolved.example.defined = {
              value = lib.mkOption {
                type = lib.types.str;
                default = "baseline";
              };
              settings = lib.mkOption {
                type = lib.types.anything;
                default = {
                  same = 1;
                  changed = 2;
                  emptied = {key = true;};
                  list = ["original"];
                };
              };
              required = lib.mkOption {type = lib.types.str;};
              nested.list = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = ["one" "two"];
              };
            };
            config._.resolved.example.defined = {
              value = "selected";
              required = "provided";
              settings = {
                same = 1;
                changed = 3;
                emptied = {};
                list = [];
                added = null;
              };
            };
          }
        ]
        ++ lib.optional (override != null) {
          _.resolved.terminal.emulators.ghostty.defined.enable = override;
        };
    };
  expectedChanges = {
    value = "selected";
    required = "provided";
    settings = {
      changed = 3;
      emptied = {};
      list = [];
      added = null;
    };
  };
  enabled = (evaluate true null).config;
  disabled = (evaluate false null).config;
  overridden = (evaluate true false).config;
  configured =
    ((evaluate true null).extendModules {
      modules = [
        {
          _.resolved.terminal.emulators.ghostty.defined = {
            settings.font-size = 17;
            settings.keybind = lib.mkForce ["ctrl+q=quit"];
            home.sessionVariables.GHOSTTY_TEST = "configured";
            home.shellAliases.gt = "ghostty";
            package =
              package
              // {
                name = "alternate-ghostty";
                outPath = "/nix/store/alternate-ghostty";
              };
          };
        }
      ];
    }).config;
  themed =
    ((evaluate true null).extendModules {
      specialArgs.style.opacity.terminal.dark = 0.75;
      modules = [{_.resolved.interface.panels.active = "dms-shell";}];
    }).config;
in
  assert enabled._.defaults.terminal.emulators.ghostty.enable == false;
  assert disabled._.defaults == enabled._.defaults;
  assert enabled._.defaults.example.value == "baseline";
  assert enabled._.defaults.example.nested.list == ["one" "two"];
  assert enabled._.resolved.example.defined.value == "selected";
  assert !(enabled._.defaults.terminal.emulators.ghostty ? defined);
  assert enabled._.updates
  == {
    example = expectedChanges;
    terminal.emulators.ghostty.enable = true;
  };
  assert disabled._.updates == {example = expectedChanges;};
  assert overridden._.updates == {example = expectedChanges;};
  assert themed.programs.ghostty.settings.theme == "dankcolors";
  assert themed.programs.ghostty.settings.config-file == "?/tmp/ghostty-test/ghostty/dotdots-opacity";
  assert themed._.defaults.terminal.emulators.ghostty.settings.background-opacity == 1.0;
  assert themed._.updates.terminal.emulators.ghostty.settings
  == {
    background-opacity = 0.75;
    theme = "dankcolors";
    config-file = "?/tmp/ghostty-test/ghostty/dotdots-opacity";
  };
  assert configured.programs.ghostty.settings.font-size == 17;
  assert configured.programs.ghostty.settings.copy-on-select == "clipboard";
  assert configured.programs.ghostty.settings.keybind == ["ctrl+q=quit"];
  assert configured.programs.ghostty.package.name == "alternate-ghostty";
  assert configured.home.sessionVariables.GHOSTTY_TEST == "configured";
  assert configured.home.shellAliases.gt == "ghostty";
  assert configured._.defaults.terminal.emulators.ghostty.settings.font-size == 10;
  assert configured._.updates.terminal.emulators.ghostty.settings.font-size == 17;
  assert enabled.programs.ghostty.enable;
  assert !disabled.programs.ghostty.enable;
  assert !overridden.programs.ghostty.enable;
  assert overridden._.resolved.terminal.emulators.ghostty.defined.enable == false; {passed = true;}
