{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) attrByPath isAttrs;
  inherit (lib.lists) all any elem isList;
  inherit (lib.strings) typeOf;
  inherit (_.trivial.types) validate;
  inherit (_.trivial.tests) mkTest runTests mkThrows;

  toPath = name:
    if isList name
    then name
    else [name];

  # True if basePath ++ path is true OR has .enable == true
  isPathEnabled = {
    attrset,
    basePath,
    path,
  }: let
    fullPath = basePath ++ toPath path;
    direct = attrByPath fullPath false attrset;
    withEnable = attrByPath (fullPath ++ ["enable"]) false attrset;
  in
    direct == true || withEnable == true;

  checkArgs = fnName: {
    attrset,
    basePath,
    names,
  }:
    if !isAttrs attrset
    then throw "${fnName}: attrset must be an attribute set, got ${typeOf attrset}"
    else if !isList basePath
    then throw "${fnName}: basePath must be a list, got ${typeOf basePath}"
    else if !isList names
    then throw "${fnName}: names must be a list, got ${typeOf names}"
    else null;

  /**
  Check if any of a set of attributes is effectively enabled.

  An entry is considered enabled if either:
  - `basePath ++ toPath name` is `true`, or
  - `basePath ++ toPath name ++ ["enable"]` is `true`.

  This matches patterns like:
  - `services.nginx.enable = true;`
  - `services.displayManager.gdm.wayland = true;`

  Type:
    anyEnabled :: { attrset :: AttrSet, basePath :: [String], names :: [String | [String]] } -> Bool
  */
  anyEnabled = {
    attrset,
    basePath,
    names,
  }: let
    __checked = checkArgs "anyEnabled" {inherit attrset basePath names;};
  in
    any (
      name:
        isPathEnabled {
          inherit attrset basePath;
          path = name;
        }
    )
    names;

  /**
  Check if all of a set of attributes are effectively enabled.

  Same notion of “enabled” as anyEnabled:
  - Direct boolean true at `basePath ++ toPath name`, or
  - `.enable == true` at that path.

  Type:
    allEnabled :: { attrset :: AttrSet, basePath :: [String], names :: [String | [String]] } -> Bool
  */
  allEnabled = {
    attrset,
    basePath,
    names,
  }: let
    __checked = checkArgs "allEnabled" {inherit attrset basePath names;};
  in
    all (
      name:
        isPathEnabled {
          inherit attrset basePath;
          path = name;
        }
    )
    names;

  waylandWindowManager = config:
    anyEnabled {
      attrset = config;
      basePath = ["wayland" "windowManager"];
      names = ["hyprland" "river" "sway" "wayfire"];
    }
    || anyEnabled {
      attrset = config;
      basePath = ["programs"];
      names = ["niri"];
    };

  waylandDesktopManager = config:
    anyEnabled {
      attrset = config;
      basePath = ["services" "desktopManager"];
      names = ["cosmic"];
    };

  waylandDisplayManager = config: let
    attrset = config;
    basePath = ["services" "displayManager"];
  in
    allEnabled {
      inherit attrset basePath;
      names = ["gdm" ["gdm" "wayland"]];
    }
    || allEnabled {
      inherit attrset basePath;
      names = ["cosmic-greeter" ["cosmic-greeter" "wayland"]];
    }
    || allEnabled {
      inherit attrset basePath;
      names = ["sddm" ["sddm" "wayland"]];
    };

  waylandDefinedInterface = interface:
    ((interface.displayProtocol or null) == "wayland")
    || (interface.desktopEnvironment or null) == "cosmic"
    || (elem (interface.windowManager or null) [
      "sway"
      "hyprland"
      "river"
      "niri"
    ]);

  /**
  Heuristic check for Wayland session/system in NixOS + Home Manager configs.

  Considers:
  - Wayland window managers under `wayland.windowManager.*.enable`
  - Wayland desktop managers under `services.desktopManager.*`
  - Display managers where either `.enable` or `.wayland` is true
  - Explicit interface fields:
      displayProtocol = "wayland" | "x11"
      desktopEnvironment = "cosmic" | ...
      windowManager = "sway" | "hyprland" | "river" | "niri"

  Type:
    waylandEnabled :: { config :: AttrSet, interface :: AttrSet } -> Bool
  */
  waylandEnabled = {
    config,
    interface ? {},
  }: let
    fnName = "waylandEnabled";

    cfg = validate {
      inherit fnName;
      argName = "config";
      predicate = isAttrs;
      expected = "set";
      actual = config;
    };

    ifc = validate {
      inherit fnName;
      argName = "interface";
      predicate = isAttrs;
      expected = "set";
      actual = interface;
    };

    isWaylandWM = waylandWindowManager cfg;
    isWaylandDE = waylandDesktopManager cfg;
    isWaylandDP = waylandDisplayManager cfg;
    isWaylandAPI = waylandDefinedInterface ifc;
  in
    isWaylandWM || isWaylandDE || isWaylandDP || isWaylandAPI;
in {
  inherit
    allEnabled
    anyEnabled
    waylandEnabled
    ;

  _rootAliases = {
    isAllEnabled = allEnabled;
    isAnyEnabled = anyEnabled;
    isWaylandEnabled = waylandEnabled;
  };

  _tests = runTests {
    anyEnabled = {
      detectsEnabledViaEnable = mkTest {
        expected = true;
        expr = anyEnabled {
          attrset = {
            services.nginx.enable = true;
            services.apache.enable = false;
          };
          basePath = ["services"];
          names = ["nginx" "apache"];
        };
      };

      detectsEnabledViaDirectBool = mkTest {
        expected = true;
        expr = anyEnabled {
          attrset = {
            services.displayManager.gdm.wayland = true;
          };
          basePath = ["services" "displayManager"];
          names = [["gdm" "wayland"]];
        };
      };

      returnsFalseWhenNoneEnabled = mkTest {
        expected = false;
        expr = anyEnabled {
          attrset = {
            services.nginx.enable = false;
            services.apache.enable = false;
          };
          basePath = ["services"];
          names = ["nginx" "apache"];
        };
      };

      handlesEmptyNames = mkTest {
        expected = false;
        expr = anyEnabled {
          attrset = {};
          basePath = ["services"];
          names = [];
        };
      };

      rejectsInvalidAttrset = mkThrows (
        anyEnabled {
          attrset = "invalid";
          basePath = [];
          names = [];
        }
      );
    };

    allEnabled = {
      detectsAllEnabledViaEnable = mkTest {
        expected = true;
        expr = allEnabled {
          attrset = {
            services.nginx.enable = true;
            services.postgresql.enable = true;
          };
          basePath = ["services"];
          names = ["nginx" "postgresql"];
        };
      };

      detectsOneDisabled = mkTest {
        expected = false;
        expr = allEnabled {
          attrset = {
            services.nginx.enable = true;
            services.postgresql.enable = false;
          };
          basePath = ["services"];
          names = ["nginx" "postgresql"];
        };
      };

      handlesNestedPathsMixed = mkTest {
        expected = true;
        expr = allEnabled {
          attrset = {
            services.displayManager.gdm.enable = true;
            services.displayManager.gdm.wayland = true;
          };
          basePath = ["services" "displayManager"];
          names = ["gdm" ["gdm" "wayland"]];
        };
      };

      detectsDirectFalse = mkTest {
        expected = false;
        expr = allEnabled {
          attrset = {
            services.displayManager.sddm.enable = true;
            services.displayManager.sddm.wayland = false;
          };
          basePath = ["services" "displayManager"];
          names = ["sddm" ["sddm" "wayland"]];
        };
      };

      rejectsInvalidAttrset = mkThrows (
        allEnabled {
          attrset = "nope";
          basePath = ["services"];
          names = ["nginx"];
        }
      );
    };
  };
}
