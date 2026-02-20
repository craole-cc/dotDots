{host, ...}: let
  locale = host.localization or {};
in {
  _module.args.locale = {
    city = locale.city or "Mandeville, Jamaica";
    timeZone = locale.timeZone or "America/Jamaica";
    defaultLocale = locale.defaultLocale or "en_US.UTF-8";
    locator = locale.locator or "geoclue2";
    latitude = locale.latitude or 18.015;
    longitude = locale.longitude or 77.49;
  };
}
