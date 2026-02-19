{lib, ...}: let
  inherit (lib.attrsets) catAttrs mapAttrsToList optionalAttrs;
  inherit (lib.lists) sort head;

  /**
  Helper to resolve displays from either explicit argument or host config

  # Type:
    ```nix
    { host? :: AttrSet, displays? :: AttrSet } -> AttrSet
    ```

  # Example:
    ```nix
    getAll { host = { devices.display = {...}; }; }
    => {...}
    ```
  */
  getAll = {
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
    getSorted :: AttrSet -> [Attrsets]
    ```

  # Arguments
    - {host?{},displays?(host.devices.displays or {}),...}: Attrset of monitor configurations keyed by connector name

  # Returns
    List of monitors with name included, sorted by priority

  # Example
    ```nix
    getSorted { displays = { "HDMI-A-2" = { priority = 1; resolution = "1920x1080"; }; "HDMI-A-3" = {priority = 0; resolution = "2560x1440";}; }; }
    => [
      { name = "HDMI-A-3"; priority = 0; resolution = "2560x1440"; ... }
      { name = "DP-3"; priority = 1; resolution = "1600x900"; ... }
    ]
  ```
  */
  getSorted = {
    host ? {},
    displays ? {},
    ...
  }:
    sort
    (a: b: (a.priority or 999) < (b.priority or 999))
    (
      mapAttrsToList (name: monitor: monitor // {inherit name;})
      (getAll {inherit host displays;})
    );

  /**
  Get primary monitor

  Returns the monitor with lowest priority number (priority 0)

  # Type
    ```
    getPrimary :: AttrSet -> Monitor | null
    ```

  # Arguments
    - {host?{},displays?(host.devices.displays or {}),...}: Attrset of monitor configurations

  # Returns
    Monitor attrset with name included, or null if no monitors

  # Example
    ```nix
    getPrimary displays
    => { name = "HDMI-A-3"; priority = 0; resolution = "2560x1440"; name = "HDMI-A-2"; priority = 1; resolution = "1920x1080";... }
    ```
  */
  getPrimary = {
    host ? {},
    displays ? {},
    ...
  }: let
    sortedMonitors = getSorted {inherit host displays;};
  in
    optionalAttrs (sortedMonitors != [] && sortedMonitors != null)
    (head sortedMonitors);

  # getPrimary = {
  #   host ? {},
  #   displays ? {},
  #   ...
  # }: let
  #   sortedMonitors = getSorted {inherit host displays;};
  # in
  #   if sortedMonitors?priority
  #   then sortedMonitors
  #   else {};

  /**
  Get primary monitor name

  Returns just the connector name string of the primary monitor

  # Type
    ```
    getPrimaryName :: AttrSet -> String | null
    ```

  # Arguments
    - {host?{},displays?(host.devices.displays or {}),...}: Attrset of monitor configurations

  # Returns
    String connector name or null

  # Example
    ```nix
    getPrimaryName displays
    => "HDMI-A-3"
    ```
  */
  getPrimaryName = {
    host ? {},
    displays ? {},
    ...
  }: let
    primary = getPrimary {inherit host displays;};
  in
    if primary?name
    then primary.name
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
    name,
    ...
  }:
    (getAll {inherit host displays;}).${name} or {};

  /**
  Get all monitor names

  Returns list of all connector names

  # Type
  ```
  getNames :: AttrSet -> [String]
  ```

  # Arguments
    - {host?{},displays?(host.devices.displays or {}),...}: Attrset of monitor configurations

  # Returns
    List of connector name strings

  # Example
    ```nix
    getNames displays
    => [ "HDMI-A-3" "DP-3" "HDMI-A-2" ]
    ```
  */
  getNames = {
    host ? {},
    displays ? {},
    ...
  }:
    catAttrs "name" (getSorted {inherit host displays;});

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
    map mkHyprlandMonitor (getSorted {inherit host displays;});
  exports = {
    inherit
      getAll
      getSorted
      getPrimary
      getPrimaryName
      getDisplay
      getNames
      mkHyprlandMonitor
      mkHyprlandMonitors
      ;
  };
in
  exports // {_rootAliases = exports;}
