{
  host,
  lib,
  ...
}: let
  inherit (lib.lists) elem;
  loc = host.localization or {};
in {
  time = {
    timeZone = loc.timeZone or null;
    hardwareClockInLocalTime = elem "dualboot-windows" (host.functionalities or []);
  };

  location = {
    latitude = loc.latitude or null;
    longitude = loc.longitude or null;
    provider = loc.locator or "geoclue2";
  };

  i18n = {
    defaultLocale = loc.defaultLocale or null;
  };
}
