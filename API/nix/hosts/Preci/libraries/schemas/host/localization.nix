{lib, ...}: let
  inherit (lib.attrsets) recursiveUpdate;

  default = {
    latitude = null;
    longitude = null;
    city = null;
    timeZone = null;
    defaultLocale = "en_US.UTF-8";
  };

  resolve = {
    args ? {},
    localization ? args.localization or {},
  }:
    recursiveUpdate default localization;
in {inherit default resolve;}
