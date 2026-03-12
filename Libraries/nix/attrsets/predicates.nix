{
  _,
  lib,
  ...
}: let
  inherit (_.debug.assertions) mkTest mkThrows;
  inherit (_.debug.runners) runTests;
  inherit (_.types.generators) validate;
  inherit (_.content.empty) isNotEmpty;
  inherit (lib.attrsets) attrByPath;
  inherit (lib.lists) all any elem isList;

  /**
  Check whether a value is an attribute set.

  # Type
  ```nix
  isAttrs :: any -> bool
  ```

  # Examples
  ```nix
  isAttrs { foo = "bar"; }  # => true
  isAttrs "foo"             # => false
  isAttrs []                # => false
  ```
  */
  isAttrs = lib.attrsets.isAttrs;

  /**
  Check whether a value is a "special" typed attrset — one with a `_type` attribute.

  Used internally to detect tagged union values produced by `lib.types`.

  # Type
  ```nix
  isTyped :: any -> bool
  ```

  # Examples
  ```nix
  isTyped { _type = "option"; }  # => true
  isTyped { foo = "bar"; }       # => false
  isTyped "foo"                  # => false
  ```
  */
  isTyped = v: isAttrs v && (v._type or null) != null;

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

  exports = {
    inherit
      isAttrs
      isTyped
      allEnabled
      anyEnabled
      waylandEnabled
      ;
    isAllEnabledAttrs = allEnabled;
    isAnyEnabledAttrs = anyEnabled;
    isWaylandEnabledAttrs = waylandEnabled;
    isTypedAttrs = isTyped;
  };
in
  exports
  // {
    _rootAliases = {
      inherit
        (exports)
        isAttrs
        isTypedAttrs
        isAllEnabledAttrs
        isAnyEnabledAttrs
        isWaylandEnabledAttrs
        ;
    };

    _tests = runTests {
      isAttrs = {
        detectsAttrset = mkTest {
          desired = true;
          command = ''isAttrs { foo = "bar"; }'';
          outcome = isAttrs {foo = "bar";};
        };
        rejectsString = mkTest {
          desired = false;
          command = ''isAttrs "foo"'';
          outcome = isAttrs "foo";
        };
        rejectsList = mkTest {
          desired = false;
          command = "isAttrs []";
          outcome = isAttrs [];
        };
        rejectsNull = mkTest {
          desired = false;
          command = "isAttrs null";
          outcome = isAttrs null;
        };
        rejectsInt = mkTest {
          desired = false;
          command = "isAttrs 1";
          outcome = isAttrs 1;
        };
        emptySetIsAttrs = mkTest {
          desired = true;
          command = "isAttrs {}";
          outcome = isAttrs {};
        };
      };

      isTyped = {
        detectsTypeField = mkTest {
          desired = true;
          command = ''isTyped { _type = "option"; }'';
          outcome = isTyped {_type = "option";};
        };
        rejectsAttrsWithoutType = mkTest {
          desired = false;
          command = ''isTyped { foo = "bar"; }'';
          outcome = isTyped {foo = "bar";};
        };
        rejectsEmptyAttrs = mkTest {
          desired = false;
          command = "isTyped {}";
          outcome = isTyped {};
        };
        rejectsString = mkTest {
          desired = false;
          command = ''isTyped "foo"'';
          outcome = isTyped "foo";
        };
        rejectsNull = mkTest {
          desired = false;
          command = "isTyped null";
          outcome = isTyped null;
        };
        typeNullDoesNotCount = mkTest {
          desired = false;
          command = "isTyped { _type = null; }";
          outcome = isTyped {_type = null;};
        };
      };

      anyEnabled = {
        detectsEnabledViaEnable = mkTest {
          desired = true;
          command = ''anyEnabled { attrset = { services.nginx.enable = true; }; basePath = ["services"]; names = ["nginx" "apache"]; }'';
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
          command = ''anyEnabled { attrset = { services.displayManager.gdm.wayland = true; }; basePath = ["services" "displayManager"]; names = [["gdm" "wayland"]]; }'';
          outcome = anyEnabled {
            attrset = {services.displayManager.gdm.wayland = true;};
            basePath = ["services" "displayManager"];
            names = [["gdm" "wayland"]];
          };
        };

        returnsFalseWhenNoneEnabled = mkTest {
          desired = false;
          command = ''anyEnabled { attrset = { services.nginx.enable = false; services.apache.enable = false; }; basePath = ["services"]; names = ["nginx" "apache"]; }'';
          outcome = anyEnabled {
            attrset = {
              services.nginx.enable = false;
              services.apache.enable = false;
            };
            basePath = ["services"];
            names = ["nginx" "apache"];
          };
        };

        returnsFalseForEmptyAttrset = mkTest {
          desired = false;
          command = ''anyEnabled { attrset = {}; basePath = ["services"]; names = ["nginx"]; }'';
          outcome = anyEnabled {
            attrset = {};
            basePath = ["services"];
            names = ["nginx"];
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
          command = ''allEnabled { attrset = { services.nginx.enable = true; services.postgresql.enable = true; }; basePath = ["services"]; names = ["nginx" "postgresql"]; }'';
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
          command = ''allEnabled { attrset = { services.nginx.enable = true; services.postgresql.enable = false; }; basePath = ["services"]; names = ["nginx" "postgresql"]; }'';
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
          command = ''allEnabled { attrset = { services.displayManager.gdm.enable = true; services.displayManager.gdm.wayland = true; }; basePath = ["services" "displayManager"]; names = ["gdm" ["gdm" "wayland"]]; }'';
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
          command = ''allEnabled { attrset = { services.displayManager.sddm.enable = true; services.displayManager.sddm.wayland = false; }; basePath = ["services" "displayManager"]; names = ["sddm" ["sddm" "wayland"]]; }'';
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

      waylandEnabled = {
        detectsHyprland = mkTest {
          desired = true;
          command = ''waylandEnabled { config = { wayland.windowManager.hyprland.enable = true; }; }'';
          outcome = waylandEnabled {
            config = {wayland.windowManager.hyprland.enable = true;};
          };
        };
        detectsSway = mkTest {
          desired = true;
          command = ''waylandEnabled { config = { wayland.windowManager.sway.enable = true; }; }'';
          outcome = waylandEnabled {
            config = {wayland.windowManager.sway.enable = true;};
          };
        };
        detectsNiri = mkTest {
          desired = true;
          command = ''waylandEnabled { config = { programs.niri.enable = true; }; }'';
          outcome = waylandEnabled {
            config = {programs.niri.enable = true;};
          };
        };
        detectsGdmWayland = mkTest {
          desired = true;
          command = ''waylandEnabled { config = { services.displayManager.gdm.enable = true; services.displayManager.gdm.wayland = true; }; }'';
          outcome = waylandEnabled {
            config = {
              services.displayManager.gdm.enable = true;
              services.displayManager.gdm.wayland = true;
            };
          };
        };
        gdmWithoutWaylandIsFalse = mkTest {
          desired = false;
          command = ''waylandEnabled { config = { services.displayManager.gdm.enable = true; }; }'';
          outcome = waylandEnabled {
            config = {services.displayManager.gdm.enable = true;};
          };
        };
        detectsInterfaceDisplayProtocol = mkTest {
          desired = true;
          command = ''waylandEnabled { config = {}; interface = { displayProtocol = "wayland"; }; }'';
          outcome = waylandEnabled {
            config = {};
            interface = {displayProtocol = "wayland";};
          };
        };
        detectsInterfaceWindowManager = mkTest {
          desired = true;
          command = ''waylandEnabled { config = {}; interface = { windowManager = "hyprland"; }; }'';
          outcome = waylandEnabled {
            config = {};
            interface = {windowManager = "hyprland";};
          };
        };
        returnsFalseForEmptyConfig = mkTest {
          desired = false;
          command = "waylandEnabled { config = {}; }";
          outcome = waylandEnabled {config = {};};
        };
        rejectsInvalidConfig = mkThrows (waylandEnabled {config = "nope";});
        rejectsInvalidInterface = mkThrows (waylandEnabled {
          config = {};
          interface = "nope";
        });
      };
    };
  }
