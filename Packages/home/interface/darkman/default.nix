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
  inherit
    (pkgs)
    dbus
    dconf
    libnotify
    replaceVars
    sd
    writeShellScript
    ;

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
    writeShellScript "darkman-toggle-${polarity}" (replaceVars ./toggle.sh {
      cmdSd = "${sd}/bin/sd";
      cmdDbus = "${dbus}/bin/dbus-send";
      cmdDconf = "${dconf}/bin/dconf";
      cmdNotify = "${libnotify}/bin/notify-send";
      cmdWallman = "${paths.wallpapers.manager}";
      cfgPolarity = polarity;
      cfgApi = "${paths.api.user}";
    });
in {
  services.darkman = mkIf enable {
    inherit enable;
    settings = {inherit lat lng usegeoclue;};
    darkModeScripts.nixos-theme = toggle "dark";
    lightModeScripts.nixos-theme = toggle "light";
  };
}
