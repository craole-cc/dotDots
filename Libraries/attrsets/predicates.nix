{lib, ...}: let
  inherit (lib.attrsets) attrByPath;
  inherit (lib.lists) all any elem;

  /**
  Check if any of a set of attributes has `.enable == true`.

  anyEnabled {
    attrset = config;
    basePath = [ "wayland" "windowManager" ];
    names = [ "sway" "hyprland" ];
  }
  */
  isAnyEnabled = {
    attrset,
    basePath,
    names,
  }:
    any
    (
      name:
        attrByPath (basePath ++ [name "enable"]) false attrset
    )
    names;

  isAllEnabled = {
    attrset,
    basePath,
    names,
  }:
    all (name: attrByPath (basePath ++ [name "enable"]) false attrset) names;

  /**
  Heuristic “is this a Wayland system/session?” for NixOS+HM configs.
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

    #~@ Wayland Desktop environments with
    isWaylandDE =
      config.services.desktopManager.cosmic.enable or false;

    #~@ Display managers with Wayland toggles
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

    isAPIDefined =
      ((interface.displayProtocol or null) == "wayland")
      || (interface.desktopEnvironment or null) == "cosmic"
      || (elem (interface.windowManager or null) ["sway" "hyprland" "river" "niri"]);
  in
    isWaylandWM || isWaylandDE || isWaylandDP || isAPIDefined;
in {
  inherit
    isAllEnabled
    isAnyEnabled
    isWaylandEnabled
    ;
}
