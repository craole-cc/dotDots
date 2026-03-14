{lib, ...}: let
  inherit (lib.lists) elem;
  inherit (lib.attrsets) recursiveUpdate;

  defaults = {
    timeZone = null;
    defaultLocale = null;
    latitude = null;
    longitude = null;
    locator = "geoclue2";
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
in {inherit mkLocale defaults;}
