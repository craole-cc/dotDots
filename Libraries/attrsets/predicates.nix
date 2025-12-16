{lib, ...}: let
  inherit (lib.attrsets) attrByPath;
  inherit (lib.lists) all any elem;

  /**
  Check if any of a set of attributes has `.enable == true`.

  Useful for detecting if at least one service/feature is enabled in a configuration,
  particularly in NixOS/Home Manager conditional logic.

  # Type
  ```
  isAnyEnabled :: { attrset :: AttrSet, basePath :: [String], names :: [String] } -> Bool
  ```

  # Arguments
  An attribute set containing:
  - `attrset`: The configuration to check (typically `config`)
  - `basePath`: Common path prefix for all attributes
  - `names`: List of attribute names to check under basePath

  # Returns
  `true` if any `basePath ++ [name] ++ ["enable"]` equals `true`, otherwise `false`

  # Examples
  ```nix
  isAnyEnabled {
    attrset = config;
    basePath = [ "wayland" "windowManager" ];
    names = [ "sway" "hyprland" "river" ];
  }
  # => true if any wayland WM is enabled

  isAnyEnabled {
    attrset = config;
    basePath = [ "services" ];
    names = [ "nginx" "apache" "caddy" ];
  }
  # => true if any web server is enabled
  ```
  */
  isAnyEnabled = {
    attrset,
    basePath,
    names,
  }:
    any (name: attrByPath (basePath ++ [name "enable"]) false attrset) names;

  /**
  Check if all of a set of attributes have `.enable == true`.

  Useful for ensuring multiple dependencies or co-requisites are all enabled.

  # Type
  ```
  isAllEnabled :: { attrset :: AttrSet, basePath :: [String], names :: [String | [String]] } -> Bool
  ```

  # Arguments
  An attribute set containing:
  - `attrset`: The configuration to check
  - `basePath`: Common path prefix for all attributes
  - `names`: List of attribute names or paths (can mix strings and path lists)

  # Returns
  `true` if all specified paths have `.enable == true`, otherwise `false`

  # Examples
  ```nix
  isAllEnabled {
    attrset = config;
    basePath = [ "services" ];
    names = [ "postgresql" "redis" ];
  }
  # => true only if both services.postgresql.enable AND services.redis.enable are true

  # Checking nested paths with mixed syntax
  isAllEnabled {
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
  isAllEnabled = {
    attrset,
    basePath,
    names,
  }:
    all (name: attrByPath (basePath ++ [name "enable"]) false attrset) names;

  /**
  Heuristic check for Wayland session/system in NixOS + Home Manager configs.

  Detects Wayland usage by checking multiple sources:
  - Wayland window managers (sway, hyprland, river)
  - Wayland desktop environments (cosmic)
  - Display managers with Wayland enabled (GDM, SDDM)
  - Explicit interface specification

  # Type
  ```
  isWaylandEnabled :: { config :: AttrSet, interface :: AttrSet } -> Bool
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

  # Examples
  ```nix
  # Detects sway
  isWaylandEnabled { inherit config; }
  # => true if config.wayland.windowManager.sway.enable

  # Explicit specification
  isWaylandEnabled {
    inherit config;
    interface = { displayProtocol = "wayland"; };
  }
  # => true

  # Checks display manager
  isWaylandEnabled { inherit config; }
  # => true if GDM with Wayland or SDDM with Wayland enabled
  ```

  # Notes
  - Returns `false` for X11-only setups
  - Extensible: add more WMs/DEs to detection lists as needed
  */
  isWaylandEnabled = {
    config,
    interface ? {},
  }: let
    isWaylandWM = isAnyEnabled {
      attrset = config;
      basePath = ["wayland" "windowManager"];
      names = ["sway" "hyprland" "river"];
    };

    isWaylandDE =
      config.services.desktopManager.cosmic.enable or false;

    isWaylandDP =
      isAllEnabled {
        attrset = config;
        basePath = ["services" "displayManager"];
        names = [
          ["gdm" "enable"]
          ["gdm" "wayland"]
        ];
      }
      || isAllEnabled {
        attrset = config;
        basePath = ["services" "displayManager"];
        names = [
          ["sddm" "enable"]
          ["sddm" "wayland" "enable"]
        ];
      };

    isRequested =
      ((interface.displayProtocol or null) == "wayland")
      || (interface.desktopEnvironment or null) == "cosmic"
      || (elem (interface.windowManager or null) [
        "sway"
        "hyprland"
        "river"
        "niri"
      ]);
  in
    isWaylandWM || isWaylandDE || isWaylandDP || isRequested;
in {
  inherit
    isAllEnabled
    isAnyEnabled
    isWaylandEnabled
    ;
}
