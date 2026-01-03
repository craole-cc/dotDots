{lib, ...}: let
  inherit (lib.attrsets) attrNames mapAttrsToList;
  inherit (lib.lists) sort head;
  getDisplays = {
    host ? {},
    displays ? {},
    ...
  }:
    if displays != {}
    then displays
    else host.devices.display or {};

  /**
  Get all monitors sorted by priority

  Converts attrset to list, sorted by priority (0 = highest priority)

  # Type
    ```
    getDisplaysSorted :: AttrSet -> [Monitor]
    ```

  # Arguments
    - {host?{},displays?(host.devices.displays or {}),...}: Attrset of monitor configurations keyed by connector name

  # Returns
    List of monitors with name included, sorted by priority

  # Example
    ```nix
    getDisplaysSorted {
      "HDMI-A-3" = { priority = 0; resolution = "2560x1440"; ... };
      "DP-3" = { priority = 1; resolution = "1600x900"; ... };
    }
    => [
      { name = "HDMI-A-3"; priority = 0; resolution = "2560x1440"; ... }
      { name = "DP-3"; priority = 1; resolution = "1600x900"; ... }
    ]
  ```
  */
  getDisplaysSorted = {
    host ? {},
    displays ? {},
    ...
  }:
    sort
    (a: b: (a.priority or 999) < (b.priority or 999))
    (
      mapAttrsToList (name: monitor: monitor // {inherit name;})
      (getDisplays {inherit host displays;})
    );

  /**
  Get primary monitor

  Returns the monitor with lowest priority number (priority 0)

  # Type
    ```
    getDisplaysPrimary :: AttrSet -> Monitor | null
    ```

  # Arguments
    - {host?{},displays?(host.devices.displays or {}),...}: Attrset of monitor configurations

  # Returns
    Monitor attrset with name included, or null if no monitors

  # Example
    ```nix
    getDisplaysPrimary displays
    => { name = "HDMI-A-3"; priority = 0; resolution = "2560x1440"; ... }
    ```
  */
  getDisplaysPrimary = {
    host ? {},
    displays ? {},
    ...
  }: let
    sortedMonitors =
      getDisplaysSorted
      (getDisplays {inherit host displays;});
  in
    if sortedMonitors != []
    then head sortedMonitors
    else null;

  /**
  Get primary monitor name

  Returns just the connector name string of the primary monitor

  # Type
    ```
    getDisplaysPrimaryName :: AttrSet -> String | null
    ```

  # Arguments
    - {host?{},displays?(host.devices.displays or {}),...}: Attrset of monitor configurations

  # Returns
    String connector name or null

  # Example
    ```nix
    getDisplaysPrimaryName displays
    => "HDMI-A-3"
    ```
  */
  getDisplaysPrimaryName = {
    host ? {},
    displays ? {},
    ...
  }: let
    primaryMonitor = getDisplaysPrimary {inherit host displays;};
  in
    if primaryMonitor?name
    then primaryMonitor.name
    else null;

  /**
  Get monitor by name

  Lookup a specific monitor by connector name

  # Type
    ```
    getDisplay :: AttrSet -> String -> Monitor | null
    ```

  # Arguments
    - {host?{},displays?(host.devices.displays or {}),...}: Attrset of monitor configurations
    - name: Connector name to lookup

  # Returns
    Monitor attrset or null if not found

  # Example
    ```nix
    getDisplay displays "HDMI-A-3"
    => { priority = 0; resolution = "2560x1440"; ... }
    ```
  */
  getDisplay = {
    host ? {},
    displays ? {},
    ...
  }: name: (getDisplays {inherit host displays;}).${name} or null;

  /**
  Get all monitor names

  Returns list of all connector names

  # Type
  ```
  getDisplayNames :: AttrSet -> [String]
  ```

  # Arguments
    - {host?{},displays?(host.devices.displays or {}),...}: Attrset of monitor configurations

  # Returns
    List of connector name strings

  # Example
    ```nix
    getDisplayNames displays
    => [ "HDMI-A-3" "DP-3" "HDMI-A-2" ]
    ```
  */
  getDisplayNames = {
    host ? {},
    displays ? {},
    ...
  }:
    attrNames (getDisplays {inherit host displays;});

  /**
  Format monitor for Hyprland

  Converts monitor config to Hyprland format string

  # Type
    ```
    mkHyprlandMonitor :: Monitor -> String
    ```

  # Arguments
    - monitor: Monitor configuration with name included

  # Returns
    Hyprland monitor string

  # Example
    ```nix
    mkHyprlandMonitor {
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
  mkHyprlandMonitor = monitor: let
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
    mkHyprlandMonitors :: AttrSet -> [String]
    ```

  # Arguments
    - {host?{},displays?(host.devices.displays or {}),...}: Attrset of monitor configurations

  # Returns
    List of Hyprland monitor configuration strings

  # Example
    ```nix
    mkHyprlandMonitors displays
    => [
      "HDMI-A-3, 2560x1440@100, 1080x900, 1"
      "DP-3, 1600x900@60, 1080x0, 1"
      "HDMI-A-2, 1920x1080@100, 0x420, 1, transform, 3"
    ]
    ```
  */
  mkHyprlandMonitors = {
    host ? {},
    displays ? {},
    ...
  }:
    map mkHyprlandMonitor (getDisplaysSorted {inherit host displays;});
  exports = {
    inherit
      getDisplays
      getDisplaysSorted
      getDisplaysPrimary
      getDisplaysPrimaryName
      getDisplay
      getDisplayNames
      mkHyprlandMonitor
      mkHyprlandMonitors
      ;
  };
in
  exports // {_rootAliases = exports;}
