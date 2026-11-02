{lix ? (import ../.. {}).libraries.default}: let
  inherit (lix) lib;
  inherit (lix.lists.access) elemAt;
  evaluate = enabled:
    lib.evalModules {
      modules = [
        {
          options = {
            _.outputs = lib.mkOption {
              type = lib.types.attrsOf lib.types.anything;
              default = {};
            };
            assertions = lib.mkOption {
              type = lib.types.listOf lib.types.anything;
              default = [];
            };
            home.packages = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [];
            };
            settings = lib.mkOption {
              type = lib.types.attrsOf lib.types.anything;
              default = {};
            };
          };
        }
        ({config, ...}: let
          context = lix.modules.construction.mkContext {
            inherit config;
            dom = "test";
            mod = "merge";
          };
        in
          lix.modules.construction.mkConfig {
            inherit context;
            options.enable = lib.mkOption {
              type = lib.types.bool;
              default = enabled;
            };
            outputs = lib.mkMerge [
              {
                assertions = [
                  {
                    assertion = true;
                    message = "First assertion";
                  }
                ];
                home.packages = ["first"];
                settings.value = lib.mkDefault 1;
                settings.forced = 1;
              }
              (lib.mkIf false {
                assertions = throw "Disabled assertion output must remain lazy";
              })
              {
                assertions = [
                  {
                    assertion = false;
                    message = "Second assertion";
                  }
                ];
                home.packages = lib.mkAfter ["last"];
                settings.value = 2;
                settings.forced = lib.mkForce 42;
              }
              {home.packages = lib.mkBefore ["before"];}
            ];
          })
      ];
    };
  enabled = (evaluate true).config;
  implicit = enabled._.resolved.test.merge.implicit;
  disabled = (evaluate false).config;
in
  assert implicit.assertions == enabled.assertions;
  assert map (entry: entry.message) implicit.assertions == ["First assertion" "Second assertion"];
  assert !(elemAt implicit.assertions 1).assertion;
  assert implicit.home.packages == enabled.home.packages;
  assert implicit.home.packages == ["before" "first" "last"];
  assert implicit.settings == enabled.settings;
  assert implicit.settings.value == 2 && implicit.settings.forced == 42;
  assert disabled._.resolved.test.merge.implicit == {};
  assert disabled.assertions == [] && disabled.home.packages == []; {passed = true;}
