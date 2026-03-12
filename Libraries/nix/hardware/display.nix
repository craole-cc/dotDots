{
  _,
  lib,
  ...
}: let
  inherit (_.content.empty) isNotEmpty;
  inherit (_.content.fallback) orDefault;
  inherit (_.debug.assertions) mkTest mkTest';
  inherit (_.debug.runners) runTests;
  inherit (lib.attrsets) mapAttrsToList catAttrs;
  inherit (lib.lists) sort head;

  getAll = {
    host ? {},
    displays ? {},
    ...
  }:
    orDefault {
      content = displays;
      default = host.devices.display or {};
    };

  getSorted = args:
    sort
    (a: b: (a.priority or 999) < (b.priority or 999))
    (mapAttrsToList
      (name: monitor: monitor // {inherit name;})
      (getAll args));

  getPrimary = args: let
    sorted = getSorted args;
  in
    orDefault {
      content =
        if isNotEmpty sorted
        then head sorted
        else null;
      default = {};
    };

  getPrimaryName = args: (getPrimary args).name or null;

  getDisplay = {name, ...} @ args: (getAll args).${name} or {};

  getNames = args: catAttrs "name" (getSorted args);

  /**
  Format a monitor config as a Hyprland monitor string.

  # Type
  ```nix
  mkHyprlandMonitor :: AttrSet -> string
  ```

  # Examples
  ```nix
  mkHyprlandMonitor { name = "DP-1"; resolution = "2560x1440"; refreshRate = 144; position = "0x0"; scale = 1; }
  # => "DP-1, 2560x1440@144, 0x0, 1"
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

  mkHyprlandMonitors = args: map mkHyprlandMonitor (getSorted args);

  exports = {
    inherit
      getAll
      getDisplay
      getNames
      getPrimary
      getPrimaryName
      getSorted
      mkHyprlandMonitor
      mkHyprlandMonitors
      ;
  };
in
  exports
  // {
    _rootAliases = exports;

    _tests = let
      twoMonitors = {
        displays = {
          "HDMI-A-2" = {
            priority = 1;
            resolution = "1920x1080";
            refreshRate = 60;
            position = "0x0";
            scale = 1;
          };
          "DP-1" = {
            priority = 0;
            resolution = "2560x1440";
            refreshRate = 144;
            position = "1920x0";
            scale = 1;
          };
        };
      };
    in
      runTests {
        getAll = {
          prefersDisplaysArg = mkTest {
            desired = twoMonitors.displays;
            outcome = getAll twoMonitors;
            command = "getAll twoMonitors";
          };
          fallsBackToHost = mkTest {
            desired = twoMonitors.displays;
            outcome = getAll {host.devices.display = twoMonitors.displays;};
            command = "getAll { host.devices.display = twoMonitors.displays; }";
          };
          emptyWhenNone = mkTest' {} (getAll {});
        };

        getSorted = {
          primaryIsFirst = mkTest {
            desired = "DP-1";
            outcome = (head (getSorted twoMonitors)).name;
            command = "(head (getSorted twoMonitors)).name";
          };
          includesName = mkTest' true ((head (getSorted twoMonitors)) ? name);
        };

        getPrimary = {
          returnsLowestPriority = mkTest {
            desired = "DP-1";
            outcome = (getPrimary twoMonitors).name;
            command = "(getPrimary twoMonitors).name";
          };
          returnsEmptyWhenNone = mkTest' {} (getPrimary {});
        };

        getPrimaryName = {
          returnsName = mkTest' "DP-1" (getPrimaryName twoMonitors);
          returnsNull = mkTest' null (getPrimaryName {});
        };

        getDisplay = {
          findsMonitor = mkTest {
            desired = twoMonitors.displays."HDMI-A-2";
            outcome = getDisplay (twoMonitors // {name = "HDMI-A-2";});
            command = ''getDisplay (twoMonitors // { name = "HDMI-A-2"; })'';
          };
          returnsEmptyWhenMissing = mkTest' {} (getDisplay (twoMonitors // {name = "HDMI-A-99";}));
        };

        getNames = {
          returnsSortedNames = mkTest {
            desired = ["DP-1" "HDMI-A-2"];
            outcome = getNames twoMonitors;
            command = "getNames twoMonitors";
          };
        };

        mkHyprlandMonitor = {
          basicFormat = mkTest {
            desired = "DP-1, 2560x1440@144, 1920x0, 1";
            outcome = mkHyprlandMonitor {
              name = "DP-1";
              resolution = "2560x1440";
              refreshRate = 144;
              position = "1920x0";
              scale = 1;
            };
            command = ''mkHyprlandMonitor { name = "DP-1"; ... }'';
          };
          withTransform = mkTest {
            desired = "HDMI-A-1, 1920x1080@60, 0x0, 1, transform, 1";
            outcome = mkHyprlandMonitor {
              name = "HDMI-A-1";
              resolution = "1920x1080";
              refreshRate = 60;
              position = "0x0";
              scale = 1;
              transform = 1;
            };
            command = ''mkHyprlandMonitor { name = "HDMI-A-1"; transform = 1; ... }'';
          };
        };
      };
  }
