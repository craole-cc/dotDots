{lib, ...}: let
  inherit (lib.lists) elem;
  inherit (lib.attrsets) recursiveUpdate;

  __exports = {
    internal = {inherit defaults mkLocale;};
    external = {
      defaultLocale = defaults;
      mkSchemaLocale = mkLocale;
    };
  };

  defaults = {
    city = "Mandeville, Jamaica";
    timeZone = "America/Jamaica";
    defaultLocale = "en_US.UTF-8";
    locator = "geoclue2";
    latitude = 18.015;
    longitude = -77.49;
    dualBootWindows = false;
  };

  mkLocale = {
    host,
    user ? {},
  }: let
    merged =
      recursiveUpdate
      (host.localization or {})
      (user.localization or {});
    fun = host.functionalities or [];
  in
    defaults
    // merged
    // {dualBootWindows = elem "dualboot-windows" fun;};
in
  __exports.internal // {_rootAliases = __exports.external;}
