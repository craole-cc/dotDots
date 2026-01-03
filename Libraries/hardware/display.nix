{lib, ...}: let
  inherit (lib.attrsets) attrNames mapAttrsToList;
  inherit (lib.lists) sort head;

  /**
  Get all monitors sorted by priority

  Converts attrset to list, sorted by priority (0 = highest priority)

  # Type
    ```
    getSortedMonitors :: AttrSet -> [Monitor]
    ```

  # Arguments
    - displays: Attrset of monitor configurations keyed by connector name

  # Returns
    List of monitors with name included, sorted by priority

  # Example
    ```nix
    getSortedMonitors {
      "HDMI-A-3" = { priority = 0; resolution = "2560x1440"; ... };
      "DP-3" = { priority = 1; resolution = "1600x900"; ... };
    }
    => [
      { name = "HDMI-A-3"; priority = 0; resolution = "2560x1440"; ... }
      { name = "DP-3"; priority = 1; resolution = "1600x900"; ... }
    ]
    ```
  */
  getSortedMonitors = displays:
    sort
    (a: b: (a.priority or 999) < (b.priority or 999))
    (mapAttrsToList (name: monitor: monitor // {inherit name;}) displays);

  /**
  Get primary monitor

  Returns the monitor with lowest priority number (priority 0)

  # Type
    ```
    getPrimaryMonitor :: AttrSet -> Monitor | null
    ```

  # Arguments
    - displays: Attrset of monitor configurations

  # Returns
    Monitor attrset with name included, or null if no monitors

  # Example
    ```nix
    getPrimaryMonitor displays
    => { name = "HDMI-A-3"; priority = 0; resolution = "2560x1440"; ... }
    ```
  */
  getPrimaryMonitor = displays:
    if (getSortedMonitors displays) != []
    then head (getSortedMonitors displays)
    else null;

  /**
  Get primary monitor name

  Returns just the connector name string of the primary monitor

  # Type
    ```
    getPrimaryMonitorName :: AttrSet -> String | null
    ```

  # Arguments
    - displays: Attrset of monitor configurations

  # Returns
    String connector name or null

  # Example
    ```nix
    getPrimaryMonitorName displays
    => "HDMI-A-3"
    ```
  */
  getPrimaryMonitorName = displays:
    if (getPrimaryMonitor displays) != null
    then (getPrimaryMonitor displays).name
    else null;

  /**
  Get monitor by name

  Lookup a specific monitor by connector name

  # Type
    ```
    getMonitor :: AttrSet -> String -> Monitor | null
    ```

  # Arguments
    - displays: Attrset of monitor configurations
    - name: Connector name to lookup

  # Returns
    Monitor attrset or null if not found

  # Example
    ```nix
    getMonitor displays "HDMI-A-3"
    => { priority = 0; resolution = "2560x1440"; ... }
    ```
  */
  getMonitor = displays: name:
    displays.${name} or null;

  /**
  Get all monitor names

  Returns list of all connector names

  # Type
  ```
  getMonitorNames :: AttrSet -> [String]
  ```

  # Arguments
    - displays: Attrset of monitor configurations

  # Returns
    List of connector name strings

  # Example
    ```nix
    getMonitorNames displays
    => [ "HDMI-A-3" "DP-3" "HDMI-A-2" ]
    ```
  */
  getMonitorNames = displays:
    attrNames displays;

  /**
  Format monitor for Hyprland

  Converts monitor config to Hyprland format string

  # Type
    ```
    toHyprlandMonitor :: Monitor -> String
    ```

  # Arguments
    - monitor: Monitor configuration with name included

  # Returns
    Hyprland monitor string

  # Example
    ```nix
    toHyprlandMonitor {
      name = "HDMI-A-3";
      resolution = "2560x1440";
      refreshRate = 100;
      position = "0x0";
      scale = 1;
      transform = 3;
    }
    => "HDMI-A-3, 2560x1440@100, 0x0, 1, transform, 3"
    ```
  */
  toHyprlandMonitor = monitor: let
    base = "${monitor.name}, ${monitor.resolution}@${toString monitor.refreshRate}, ${monitor.position}, ${toString monitor.scale}";
    rotation =
      if monitor ? transform
      then ", transform, ${toString monitor.transform}"
      else "";
  in
    base + rotation;

  /**
  Get all monitors for Hyprland

  Returns list of Hyprland monitor strings, sorted by priority

  # Type
    ```
    toHyprlandMonitors :: AttrSet -> [String]
    ```

  # Arguments
    - displays: Attrset of monitor configurations

  # Returns
    List of Hyprland monitor configuration strings

  # Example
    ```nix
    toHyprlandMonitors displays
    => [
      "HDMI-A-3, 2560x1440@100, 1080x900, 1"
      "DP-3, 1600x900@60, 1080x0, 1"
      "HDMI-A-2, 1920x1080@100, 0x420, 1, transform, 3"
    ]
    ```
  */
  toHyprlandMonitors = displays:
    map toHyprlandMonitor (getSortedMonitors displays);

  exports = {
    inherit
      getSortedMonitors
      getPrimaryMonitor
      getPrimaryMonitorName
      getMonitor
      getMonitorNames
      toHyprlandMonitor
      toHyprlandMonitors
      ;
  };
in
  exports // {_rootAliases = exports;}
