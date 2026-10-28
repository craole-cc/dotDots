{lix ? (import ../../.. {}).libraries.default}: let
  inherit (lix) lib;
  inherit (lix.attrsets.access) attrNames;
  inherit (lix.lists.access) length;
  inherit (lix.schema.ui) mkUI normalize;

  resolve = user:
    (mkUI {
      host = {};
      inherit user;
    }).wallpaper;
  tests = {
    testDefaultEngine = {
      expr = resolve {};
      expected = {
        engine = "variety";
        backends.active = "auto";
      };
    };
    testFirstWallpaperPackageWins = {
      expr = (resolve {packages.wallpaper = ["first" "second"];}).engine;
      expected = "first";
    };
    testEmptyPackagesUseDefaultEngine = {
      expr = (resolve {packages.wallpaper = [];}).engine;
      expected = "variety";
    };
    testExplicitEngineWins = {
      expr =
        (resolve {
          packages.wallpaper = ["first" "second"];
          interface.wallpaper.engine = "explicit";
        }).engine;
      expected = "explicit";
    };
    testExplicitNullDisablesSelection = {
      expr =
        (resolve {
          packages.wallpaper = ["variety"];
          interface.wallpaper.engine = null;
        }).engine;
      expected = null;
    };
    testBackendPreferenceSurvivesNormalisation = {
      expr = resolve {interface.wallpaper.backends.active = "dms";};
      expected = {
        engine = "variety";
        backends.active = "dms";
      };
    };
    testHostWallpaperPackage = {
      expr = (mkUI {host.packages.wallpaper = ["host-engine"];}).wallpaper.engine;
      expected = "host-engine";
    };
    testUserPackagesReplaceHostPreference = {
      expr =
        (mkUI {
          host.packages.wallpaper = ["host-engine"];
          user.packages.wallpaper = ["user-engine"];
        }).wallpaper.engine;
      expected = "user-engine";
    };
    testUserEngineOverridesHostDefault = {
      expr =
        (mkUI {
          host.defaults.interface.wallpaper.engine = "host-engine";
          user.interface.wallpaper.engine = "user-engine";
        }).wallpaper.engine;
      expected = "user-engine";
    };
    testNormalisePreservesExplicitSelection = {
      expr =
        (normalize {
          wallpaper = {
            engine = null;
            backends.active = "hyprpaper";
          };
        }).wallpaper;
      expected = {
        engine = null;
        backends.active = "hyprpaper";
      };
    };
  };
in {
  total = length (attrNames tests);
  failures = lib.runTests tests;
}
