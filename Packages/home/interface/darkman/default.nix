{
  host,
  lib,
  locale,
  paths,
  pkgs,
  user,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (pkgs) replaceVarsWith;

  #~@ Location
  lat = locale.latitude or null;
  lng = locale.longitude or null;
  usegeoclue = (locale.provider or "manual") == "geoclue2";

  #~@ Style
  style = user.interface.style or host.interface.style or {};
  switch = style.autoSwitch or false;

  #~@ Enable condition
  enable =
    switch
    && (lat != null)
    && (lng != null)
    && (paths.dots != null);

  toggle = polarity:
    replaceVarsWith {
      src = ./toggle.sh;
      replacements = {
        cmdSd = "${pkgs.sd}/bin/sd";
        cmdDbus = "${pkgs.dbus}/bin/dbus-send";
        cmdDconf = "${pkgs.dconf}/bin/dconf";
        cmdNotify = "${pkgs.libnotify}/bin/notify-send";
        cmdWallman = "${paths.wallpapers.manager}";
        cfgApi = "${paths.api.user}";
        cfgPolarity = polarity;
      };
      dir = "bin";
      isExecutable = true;
    };
in {
  services.darkman = mkIf enable {
    inherit enable;
    settings = {inherit lat lng usegeoclue;};
    darkModeScripts.nixos-theme = toggle "dark";
    lightModeScripts.nixos-theme = toggle "light";
  };
}
