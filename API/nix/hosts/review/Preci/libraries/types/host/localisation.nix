{lix, ...}: let
  inherit (lix.attrsets) recursiveUpdate;

  default = {
    latitude = null;
    longitude = null;
    city = null;
    timeZone = null;
    defaultLocale = "en_US.UTF-8";
  };

  resolve = {localisation ? args.localisation or {}, ...} @ args:
    recursiveUpdate default localisation;
in {inherit default resolve;}
