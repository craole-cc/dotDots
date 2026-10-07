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

  loc = host.localisation;
in
  mkConfig {
    inherit context;
    options = {
      enable = mkTrue "Whether to enable locale settings";
      timeZone = mkOption {
        description = "System timezone";
        default = loc.timeZone;
        defaultText = literalExpression "host.localisation.timeZone";
        type = nullOr str;
      };
      defaultLocale = mkOption {
        description = "Default locale";
        default = loc.defaultLocale;
        defaultText = literalExpression "host.localisation.defaultLocale";
        type = nullOr str;
      };
      latitude = mkOption {
        description = "Geolocation latitude";
        default = loc.latitude;
        defaultText = literalExpression "host.localisation.latitude";
        type = nullOr float;
      };
      longitude = mkOption {
        description = "Geolocation longitude";
        default = loc.longitude;
        defaultText = literalExpression "host.localisation.longitude";
        type = nullOr float;
      };
      locator = mkOption {
        description = "Location provider";
        default = loc.locator;
        defaultText = literalExpression "host.localisation.locator";
        type = str;
      };
      dualBootWindows = mkEnable {
        description = "Hardware clock for Windows dual-boot";
        condition = loc.dualBootWindows;
        defaultText = literalExpression "host.localisation.dualBootWindows";
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
