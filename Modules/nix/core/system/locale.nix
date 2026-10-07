{
  config,
  lix,
  host,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "system";
    mod = "locale";
  };
  inherit (context) cfg;

  inherit (lix.modules.construction) mkConfig mkContext mkIf;
  inherit (lix.options.construction) literalExpression mkEnable mkOption mkTrue;
  inherit (lix.types.combinators) nullOr;
  inherit (lix.types.primitives) float str;

  loc = host.locale;
in
  mkConfig {
    inherit context;
    options = {
      enable = mkTrue "Whether to enable locale settings";
      timeZone = mkOption {
        description = "System timezone";
        default = loc.timeZone;
        defaultText = literalExpression "host.locale.timeZone";
        type = nullOr str;
      };
      defaultLocale = mkOption {
        description = "Default locale";
        default = loc.defaultLocale;
        defaultText = literalExpression "host.locale.defaultLocale";
        type = nullOr str;
      };
      latitude = mkOption {
        description = "Geolocation latitude";
        default = loc.latitude;
        defaultText = literalExpression "host.locale.latitude";
        type = nullOr float;
      };
      longitude = mkOption {
        description = "Geolocation longitude";
        default = loc.longitude;
        defaultText = literalExpression "host.locale.longitude";
        type = nullOr float;
      };
      locator = mkOption {
        description = "Location provider";
        default = loc.locator;
        defaultText = literalExpression "host.locale.locator";
        type = str;
      };
      dualBootWindows = mkEnable {
        description = "Hardware clock for Windows dual-boot";
        condition = loc.dualBootWindows;
        defaultText = literalExpression "host.locale.dualBootWindows";
      };
    };
    outputs = {
      time = {
        inherit (cfg) timeZone;
        hardwareClockInLocalTime = cfg.dualBootWindows;
      };
      location = mkIf (cfg.latitude != null && cfg.longitude != null) {
        inherit (cfg) latitude longitude;
        provider = cfg.locator;
      };
      i18n.defaultLocale = mkIf (cfg.defaultLocale != null) cfg.defaultLocale;
    };
  }
