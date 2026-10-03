{lix, ...}: let
  inherit (lix.attrsets) recursiveUpdate;

  default = {
    latitude = null;
    longitude = null;
    city = null;
    timeZone = null;
    defaultLocale = "en_US.UTF-8";
  };

  resolve = {localization ? args.localization or {}, ...} @ args:
    recursiveUpdate default localization;
in {inherit default resolve;}
