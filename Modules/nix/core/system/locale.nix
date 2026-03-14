{
  config,
  host,
  lib,
  top,
  ...
}: let
  dom = "config";
  mod = "locale";
  cfg = config.${dom}.${mod};

  loc = host.localization or {};
  fun = host.functionalities or [];

  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.lists) elem;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) nullOr str float;
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption mod // {default = true;};
    timeZone = mkOption {
      description = "System timezone";
      default = loc.timeZone or null;
      type = nullOr str;
    };
    defaultLocale = mkOption {
      description = "Default locale";
      default = null;
      type = nullOr str;
    };
    latitude = mkOption {
      description = "Geolocation latitude";
      default = null;
      type = nullOr float;
    };
    longitude = mkOption {
      description = "Geolocation longitude";
      default = null;
      type = nullOr float;
    };
    locator = mkOption {
      description = "Location provider";
      default = "geoclue2";
      type = str;
    };
    dualBootWindows = mkOption {
      description = "Sync hardware clock for Windows dual-boot";
      default = false;
      type = lib.types.bool;
    };
  };

  config = mkIf cfg.enable {
    ${top}.${dom}.${mod} = {
      timeZone = loc.timeZone               or cfg.timeZone;
      defaultLocale = loc.defaultLocale     or cfg.defaultLocale;
      latitude = loc.latitude               or cfg.latitude;
      longitude = loc.longitude             or cfg.longitude;
      locator = loc.locator                 or cfg.locator;
      dualBootWindows = elem "dualboot-windows" fun;
    };

    time = {
      timeZone = cfg.timeZone;
      hardwareClockInLocalTime = cfg.dualBootWindows;
    };

    location = optionalAttrs (cfg.latitude != null && cfg.longitude != null) {
      latitude = cfg.latitude;
      longitude = cfg.longitude;
      provider = cfg.locator;
    };

    i18n.defaultLocale = mkIf (cfg.defaultLocale != null) cfg.defaultLocale;
  };
}
