{lib, ...}: let
  inherit (lib.strings) concatStringsSep;
  toRegex = list: "^(${concatStringsSep "|" list})$";
  common = [
    "ags"
    "calendar"
    "notifications"
    "osd"
    "system-menu"
    "anyrun"
    "vicinae"
    "caelestia:launcher"
  ];
  panels = [
    "bar"
    "gtk-layer-shell"
  ];
  layers = common ++ panels;
in {
  layerrule = [
    "blur on, match:namespace ${toRegex layers}"
    "xray on, match:namespace ${toRegex panels}"
    "ignore_alpha 0.2, match:namespace ${toRegex panels}"
    "ignore_alpha 0.5, match:namespace ${toRegex (common ++ ["music"])}"
  ];
}
