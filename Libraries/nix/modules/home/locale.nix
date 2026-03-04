{...}: let
  mkLocale = {host}: let
    loc = host.localization or {};
  in {
    city = loc.city or "Mandeville, Jamaica";
    timeZone = loc.timeZone or "America/Jamaica";
    defaultLocale = loc.defaultLocale or "en_US.UTF-8";
    locator = loc.locator or "geoclue2";
    latitude = loc.latitude or 18.015;
    longitude = loc.longitude or (-77.49);
  };

  exports = {inherit mkLocale;};
in
  exports // {_rootAliases = {mkUserLocale = mkLocale;};}
