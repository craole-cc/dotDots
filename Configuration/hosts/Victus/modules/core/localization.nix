{
  host,
  lib,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.lists) elem;
  inherit (host) functionalities;
  inherit (host.localization)
    latitude
    longitude
    timeZone
    provider
    defaultLocale
    ;
  hasCoords = latitude != null && longitude != null;
  providerOverride = if hasCoords then provider else "geoclue2";
in
{
  config = {
    environment.sessionVariables = mkIf hasCoords {
      LONGITUDE = toString longitude;
      LATITUDE = toString latitude;
    };

    location = {
      provider = providerOverride;
      latitude = (mkIf hasCoords) latitude;
      longitude = (mkIf hasCoords) longitude;
    };

    #~@ Default locale for messages, formatting, collation, etc.
    i18n = { inherit defaultLocale; };

    time = {
      #~@ System timezone; used by systemd-timedated and friends for displaying times and dates.
      inherit timeZone;

      #~@ Keep RTC in local time only when dual-booting and following Windows’ default behaviour.
      hardwareClockInLocalTime = elem "dualboot-windows" functionalities;
    };
  };
}
