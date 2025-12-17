{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) attrByPath isAttrs;
  inherit (lib.lists) all any elem isList;
  inherit (_.types.generators) validate;
  inherit (_.trivial.tests) mkTest runTests mkThrows;
  inherit (_.trivial.emptiness) isNotEmpty;

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

  # Shared argument validation
  validateArgs = fnName: {
    attrset,
    basePath,
    names,
  }: {
    attrset = validate {
      inherit fnName;
      argName = "attrset";
      desired = "set";
      predicate = isAttrs;
      actual = attrset;
    };

    basePath = validate {
      inherit fnName;
      argName = "basePath";
      desired = "non-empty list";
      predicate = v: isList v && isNotEmpty v;
      actual = basePath;
    };

    names = validate {
      inherit fnName;
      argName = "names";
      desired = "non-empty list";
      predicate = v: isList v && isNotEmpty v;
      actual = names;
    };
  };

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
    args = validateArgs fnName {inherit attrset basePath names;};
  in
    any
    (
      name:
        isPathEnabled {
          attrset = args.attrset;
          basePath = args.basePath;
          path = name;
        }
    )
    args.names;

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
    args = validateArgs fnName {inherit attrset basePath names;};
  in
    all
    (
      name:
        isPathEnabled {
          attrset = args.attrset;
          basePath = args.basePath;
          path = name;
        }
    )
    args.names;

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
      desired = "set";
      actual = config;
    };

    ifc = validate {
      inherit fnName;
      argName = "interface";
      predicate = isAttrs;
      desired = "set";
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
        desired = true;
        outcome = anyEnabled {
          attrset = {
            services.nginx.enable = true;
            services.apache.enable = false;
          };
          basePath = ["services"];
          names = ["nginx" "apache"];
        };
      };

      detectsEnabledViaDirectBool = mkTest {
        desired = true;
        outcome = anyEnabled {
          attrset = {
            services.displayManager.gdm.wayland = true;
          };
          basePath = ["services" "displayManager"];
          names = [["gdm" "wayland"]];
        };
      };

      returnsFalseWhenNoneEnabled = mkTest {
        desired = false;
        outcome = anyEnabled {
          attrset = {
            services.nginx.enable = false;
            services.apache.enable = false;
          };
          basePath = ["services"];
          names = ["nginx" "apache"];
        };
      };

      handlesEmptyNames = mkThrows (
        anyEnabled {
          attrset = {};
          basePath = ["services"];
          names = [];
        }
      );

      rejectsInvalidAttrset = mkThrows (
        anyEnabled {
          attrset = "nope";
          basePath = ["services"];
          names = ["nginx"];
        }
      );
    };

    allEnabled = {
      detectsAllEnabledViaEnable = mkTest {
        desired = true;
        outcome = allEnabled {
          attrset = {
            services.nginx.enable = true;
            services.postgresql.enable = true;
          };
          basePath = ["services"];
          names = ["nginx" "postgresql"];
        };
      };

      detectsOneDisabled = mkTest {
        desired = false;
        outcome = allEnabled {
          attrset = {
            services.nginx.enable = true;
            services.postgresql.enable = false;
          };
          basePath = ["services"];
          names = ["nginx" "postgresql"];
        };
      };

      handlesNestedPathsMixed = mkTest {
        desired = true;
        outcome = allEnabled {
          attrset = {
            services.displayManager.gdm.enable = true;
            services.displayManager.gdm.wayland = true;
          };
          basePath = ["services" "displayManager"];
          names = ["gdm" ["gdm" "wayland"]];
        };
      };

      detectsDirectFalse = mkTest {
        desired = false;
        outcome = allEnabled {
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
