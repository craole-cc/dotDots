{
  _,
  lib,
  ...
}: let
  inherit (_.debug.assertions) mkTest mkThrows;
  inherit (_.debug.runners) runTests;
  inherit (_.types.generators) validate;
  inherit (_.values.empty) isNotEmpty;
  inherit (lib.attrsets) attrByPath isAttrs;
  inherit (lib.lists) all any elem isList;

  toPath = name:
    if isList name
    then name
    else [name];

  # True if basePath ++ path is `true` OR has `.enable == true`
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

  # Shared argument validation for anyEnabled / allEnabled
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
      outcome = attrset;
    };

    basePath = validate {
      inherit fnName;
      argName = "basePath";
      desired = "non-empty list";
      predicate = value: isList value && isNotEmpty value;
      outcome = basePath;
    };

    names = validate {
      inherit fnName;
      argName = "names";
      desired = "non-empty list";
      predicate = value: isList value && isNotEmpty value;
      outcome = names;
    };
  };

  /**
  Check if any of a set of attributes is effectively enabled.

  An entry is considered enabled if either:
  - `basePath ++ toPath name` is `true`, or
  - `basePath ++ toPath name ++ ["enable"]` is `true`.

  # Type
  ```nix
  anyEnabled :: { attrset :: AttrSet, basePath :: [string], names :: [string | [string]] } -> bool
  ```

  # Examples
  ```nix
  anyEnabled {
    attrset  = { services.nginx.enable = true; };
    basePath = ["services"];
    names    = ["nginx" "apache"];
  }
  # => true
  ```
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
    (name:
      isPathEnabled {
        attrset = args.attrset;
        basePath = args.basePath;
        path = name;
      })
    args.names;

  /**
  Check if all of a set of attributes are effectively enabled.

  Same notion of "enabled" as `anyEnabled`.

  # Type
  ```nix
  allEnabled :: { attrset :: AttrSet, basePath :: [string], names :: [string | [string]] } -> bool
  ```

  # Examples
  ```nix
  allEnabled {
    attrset  = { services.nginx.enable = true; services.postgresql.enable = true; };
    basePath = ["services"];
    names    = ["nginx" "postgresql"];
  }
  # => true
  ```
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
    (name:
      isPathEnabled {
        attrset = args.attrset;
        basePath = args.basePath;
        path = name;
      })
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
    || (elem (interface.windowManager or null) ["sway" "hyprland" "river" "niri"]);

  /**
  Check if Wayland is active via any supported mechanism.

  Inspects window managers, desktop managers, display managers, and an
  optional `interface` attrset for explicit Wayland declarations.

  # Type
  ```nix
  waylandEnabled :: { config :: AttrSet, interface :: AttrSet? } -> bool
  ```
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
      desired = "set";
      outcome = config;
    };
    ifc = validate {
      inherit fnName;
      argName = "interface";
      predicate = isAttrs;
      desired = "set";
      outcome = interface;
    };
  in
    waylandWindowManager cfg
    || waylandDesktopManager cfg
    || waylandDisplayManager cfg
    || waylandDefinedInterface ifc;
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
          attrset = {services.displayManager.gdm.wayland = true;};
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

      handlesEmptyNames = mkThrows (anyEnabled {
        attrset = {};
        basePath = ["services"];
        names = [];
      });
      rejectsInvalidAttrset = mkThrows (anyEnabled {
        attrset = "nope";
        basePath = ["services"];
        names = ["nginx"];
      });
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
