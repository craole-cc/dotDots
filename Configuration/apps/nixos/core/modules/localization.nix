{
  specialArgs,
  lib,
  pkgs,
  modulesPath,
  ...
}:
let
  inherit (specialArgs.host.location)
    latitude
    longitude
    defaultLocale
    timeZone
    ;
in
{
  i18n = {
    inherit defaultLocale;
  };

  location = {
    inherit latitude longitude;
    provider = if latitude == null || longitude == null then "geoclue2" else "manual";
  };

  time = {
    inherit timeZone;
    hardwareClockInLocalTime = lib.mkDefault true;
  };
}
