{
  config,
  lib,
  pkgs,
  top,
  lix,
  ...
}: let
  inherit (lib.modules) mkIf;

  cfg = config.${top}.inputs.interface;
  autoSwitch = config.${top}.inputs.interface.style.autoSwitch or true;

  hyprlandPortals = [
    pkgs.xdg-desktop-portal-hyprland
    pkgs.xdg-desktop-portal-gtk
  ];

  niriPortals = [
    pkgs.xdg-desktop-portal-gnome
    pkgs.xdg-desktop-portal-gtk
  ];

  defaultPortals = [pkgs.xdg-desktop-portal-gtk];

  portals =
    if cfg.windowManager == "hyprland"
    then hyprlandPortals
    else if cfg.windowManager == "niri"
    then niriPortals
    else defaultPortals;

  # Route Settings portal to darkman when autoSwitch is on,
  # otherwise fall through to gtk
  settingsImpl =
    if autoSwitch
    then ["darkman"]
    else ["gtk"];
  payload = {
    xdg.portal = {
      enable = true;
      extraPortals = portals;
      config = {
        common.default = ["*"];
        hyprland = mkIf (cfg.windowManager == "hyprland") {
          default = [
            "hyprland"
            "gtk"
          ];
          "org.freedesktop.impl.portal.Settings" = settingsImpl;
        };
        niri = mkIf (cfg.windowManager == "niri") {
          default = [
            "gnome"
            "gtk"
          ];
          "org.freedesktop.impl.portal.Settings" = settingsImpl;
        };
      };
    };
  };
  inherit (lix.modules.core.staging) mkStaged;
in {
  config = lib.mkMerge (mkStaged {
    inherit top payload;
    condition = cfg.enable;
  });
}
