# system/locale.nix
{
  config,
  host,
  lib,
  top,
  ...
}: let
  dom = "system";
  mod = "locale";
  cfg = config.${top}.${dom}.${mod};
  loc = host.localization;

  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) bool float nullOr str;
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption mod // {default = true;};
    timeZone = mkOption {
      description = "System timezone";
      default = loc.timeZone;
      type = nullOr str;
    };
    defaultLocale = mkOption {
      description = "Default locale";
      default = loc.defaultLocale;
      type = nullOr str;
    };
    latitude = mkOption {
      description = "Geolocation latitude";
      default = loc.latitude;
      type = nullOr float;
    };
    longitude = mkOption {
      description = "Geolocation longitude";
      default = loc.longitude;
      type = nullOr float;
    };
    locator = mkOption {
      description = "Location provider";
      default = loc.locator;
      type = str;
    };
    dualBootWindows = mkOption {
      description = "Hardware clock for Windows dual-boot";
      default = loc.dualBootWindows;
      type = bool;
    };
  };

  config = mkIf cfg.enable {
    time = {
      timeZone = cfg.timeZone;
      hardwareClockInLocalTime = cfg.dualBootWindows;
    };

    location = mkIf (cfg.latitude != null && cfg.longitude != null) {
      latitude = cfg.latitude;
      longitude = cfg.longitude;
      provider = cfg.locator;
    };

    i18n.defaultLocale = mkIf (cfg.defaultLocale != null) cfg.defaultLocale;
  };
}
