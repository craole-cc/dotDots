{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) attrByPath isAttrs;
  inherit (lib.lists) all any elem isList;
  inherit (_.types.generators) validate;
  inherit (_.trivial.tests) mkTest runTests mkThrows;

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
    fnName = "anyEnabled";

    as = validate {
      inherit fnName;
      argName = "attrset";
      expected = "set";
      predicate = isAttrs;
      actual = attrset;
    };

    bp = validate {
      inherit fnName;
      argName = "basePath";
      expected = "list";
      predicate = isList;
      actual = basePath;
    };

    ns = validate {
      inherit fnName;
      argName = "names";
      expected = "list";
      predicate = isList;
      actual = names;
    };
  in
    any (
      name:
        isPathEnabled {
          attrset = as;
          basePath = bp;
          path = name;
        }
    )
    ns;

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
    fnName = "allEnabled";

    as = validate {
      inherit fnName;
      argName = "attrset";
      expected = "set";
      predicate = isAttrs;
      actual = attrset;
    };

    bp = validate {
      inherit fnName;
      argName = "basePath";
      expected = "list";
      predicate = isList;
      actual = basePath;
    };

    ns = validate {
      inherit fnName;
      argName = "names";
      expected = "list";
      predicate = isList;
      actual = names;
    };
  in
    all (
      name:
        isPathEnabled {
          attrset = as;
          basePath = bp;
          path = name;
        }
    )
    ns;

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

      rejectsInvalidAttrset = mkTest {
        expected = {
          success = false;
          value = false;
        };
        expr = builtins.tryEval (
          anyEnabled {
            attrset = "invalid";
            basePath = [];
            names = [];
          }
        );
      };
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
