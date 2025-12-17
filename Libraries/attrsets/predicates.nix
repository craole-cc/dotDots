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

  /**
  Check if any of a set of attributes has `.enable == true`.

  Useful for detecting if at least one service/feature is enabled in a configuration,
  particularly in NixOS/Home Manager conditional logic.

  # Type
  ```
  anyEnabled :: { attrset :: AttrSet, basePath :: [String], names :: [String] } -> Bool
  ```

  # Arguments
  An attribute set containing:
  - `attrset`: The configuration to check (typically `config`)
  - `basePath`: Common path prefix for all attributes
  - `names`: List of attribute names to check under basePath

  # Returns
  `true` if any `basePath ++ [name] ++ ["enable"]` equals `true`, otherwise `false`

  # Throws
  - Error if `attrset` is not an attribute set
  - Error if `basePath` is not a list
  - Error if `names` is not a list

  # Examples
  ```nix
  anyEnabled {
    attrset = config;
    basePath = [ "wayland" "windowManager" ];
    names = [ "sway" "hyprland" "river" ];
  }
  # => true if any wayland WM is enabled

  anyEnabled {
    attrset = config;
    basePath = [ "services" ];
    names = [ "nginx" "apache" "caddy" ];
  }
  # => true if any web server is enabled
  ```
  */
  anyEnabled = {
    attrset,
    basePath,
    names,
  }:
    if !isAttrs attrset
    then throw "anyEnabled: attrset must be an attribute set, got ${typeOf attrset}"
    else if !isList basePath
    then throw "anyEnabled: basePath must be a list, got ${typeOf basePath}"
    else if !isList names
    then throw "anyEnabled: names must be a list, got ${typeOf names}"
    else any (name: attrByPath (basePath ++ [name "enable"]) false attrset) names;

  /**
  Check if all of a set of attributes have `.enable == true`.

  Useful for ensuring multiple dependencies or co-requisites are all enabled.

  # Type
  ```
  allEnabled :: { attrset :: AttrSet, basePath :: [String], names :: [String | [String]] } -> Bool
  ```

  # Arguments
  An attribute set containing:
  - `attrset`: The configuration to check
  - `basePath`: Common path prefix for all attributes
  - `names`: List of attribute names or paths (can mix strings and path lists)

  # Returns
  `true` if all specified paths have `.enable == true`, otherwise `false`

  # Throws
  - Error if `attrset` is not an attribute set
  - Error if `basePath` is not a list
  - Error if `names` is not a list

  # Examples
  ```nix
  allEnabled {
    attrset = config;
    basePath = [ "services" ];
    names = [ "postgresql" "redis" ];
  }
  # => true only if both services.postgresql.enable AND services.redis.enable are true

  # Checking nested paths with mixed syntax
  allEnabled {
    attrset = config;
    basePath = [ "services" "displayManager" ];
    names = [
      [ "gdm" "enable" ]
      [ "gdm" "wayland" ]
    ];
  }
  # => true if both services.displayManager.gdm.enable and gdm.wayland are true
  ```
  */
  allEnabled = {
    attrset,
    basePath,
    names,
  }:
    if !isAttrs attrset
    then throw "allEnabled: attrset must be an attribute set, got ${typeOf attrset}"
    else if !isList basePath
    then throw "allEnabled: basePath must be a list, got ${typeOf basePath}"
    else if !isList names
    then throw "allEnabled: names must be a list, got ${typeOf names}"
    else let
      toPath = name:
        if isList name
        then name
        else [name];
    in
      all
      (name: attrByPath (basePath ++ toPath name ++ ["enable"]) false attrset)
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

  Detects Wayland usage by checking multiple sources:
  - Wayland window managers (sway, hyprland, river)
  - Wayland desktop environments (cosmic)
  - Display managers with Wayland enabled (GDM, SDDM)
  - Explicit interface specification

  # Type
  ```
  waylandEnabled :: { config :: AttrSet, interface :: AttrSet } -> Bool
  ```

  # Arguments
  An attribute set containing:
  - `config`: NixOS/Home Manager configuration
  - `interface`: Optional host/user API specification with fields:
    - `displayProtocol`: "wayland" | "x11"
    - `desktopEnvironment`: Desktop environment name
    - `windowManager`: Window manager name

  # Returns
  `true` if any Wayland indicator is detected, otherwise `false`

  # Throws
  - Error if `config` is not an attribute set
  - Error if `interface` is provided but not an attribute set

  # Examples
  ```nix
  # Detects sway
  waylandEnabled { inherit config; }
  # => true if config.wayland.windowManager.sway.enable

  # Explicit specification
  waylandEnabled {
    inherit config;
    interface = { displayProtocol = "wayland"; };
  }
  # => true

  # Checks display manager
  waylandEnabled { inherit config; }
  # => true if GDM with Wayland or SDDM with Wayland enabled
  ```

  # Notes
  - Returns `false` for X11-only setups
  - Extensible: add more WMs/DEs to detection lists as needed
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
      detectsEnabled = mkTest {
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

      returnsFalseWhenNoneEnabled = mkTest {
        expected = false;
        expr = anyEnabled {
          attrset = {services.nginx.enable = false;};
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
      detectsAllEnabled = mkTest {
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

      handlesNestedPaths = mkTest {
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
