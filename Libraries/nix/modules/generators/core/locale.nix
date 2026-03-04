{_, ...}: let
  inherit (_.lists.predicates) isIn;

  mkLocale = {host, ...}: let
    loc = host.localization or {};
  in {
    #~@ Timezone
    time = {
      timeZone = loc.timeZone or null;
      hardwareClockInLocalTime = isIn "dualboot-windows" (host.functionalities or []);
    };

    #~@ Geolocation
    location = {
      latitude = loc.latitude or null;
      longitude = loc.longitude or null;
      provider = loc.locator or "geoclue2";
    };

    #~@ Internationalization
    i18n.defaultLocale = loc.defaultLocale or null;
  };

  exports = {inherit mkLocale;};
in
  exports // {_rootAliases = exports;}
