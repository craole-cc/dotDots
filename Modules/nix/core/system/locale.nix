{
  config,
  lix,
  host,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "interface";
    sub = null;
    mod = "locale";
  };
  inherit (context) cfg mod;
  inherit (lix.options.construction) literalExpression mkEnable mkOption;
  inherit (lix.types.combinators) nullOr;
  inherit (lix.types.primitives) float str;
  inherit (lix.options.construction) mkTrue;
  inherit (lix.modules.construction) mkConfig mkContext;

  loc = host.localization;
in
  mkConfig {
    inherit context;
    options = {
      enable = mkTrue "Whether to enable locale settings";
      autoLogin = {
        enable = mkTrue "Whether to enable automatic login for the primary user.";
        timeZone = mkOption {
          description = "System timezone";
          default = loc.timeZone;
          defaultText = literalExpression "host.localization.timeZone";
          type = nullOr str;
        };
        defaultLocale = mkOption {
          description = "Default locale";
          default = loc.defaultLocale;
          defaultText = literalExpression "host.localization.defaultLocale";
          type = nullOr str;
        };
        latitude = mkOption {
          description = "Geolocation latitude";
          default = loc.latitude;
          defaultText = literalExpression "host.localization.latitude";
          type = nullOr float;
        };
        longitude = mkOption {
          description = "Geolocation longitude";
          default = loc.longitude;
          defaultText = literalExpression "host.localization.longitude";
          type = nullOr float;
        };
        locator = mkOption {
          description = "Location provider";
          default = loc.locator;
          defaultText = literalExpression "host.localization.locator";
          type = str;
        };
        dualBootWindows = mkEnable {
          description = "Hardware clock for Windows dual-boot";
          condition = loc.dualBootWindows;
          defaultText = literalExpression "host.localization.dualBootWindows";
        };
        user = mkOption {
          description = "Username for automatic login. Defaults to the primary user's name.";
          default = host.users.primary.name or null;
          defaultText = literalExpression "host.users.data.primary.name or null";
          example = literalExpression ''"craole"'';
          type = nullOr str;
        };
      };
    };
    outputs = {
      # programs.${mod} = {
      #   inherit (cfg) enable;
      #   lfs.enable = cfg.enableLFS;
      #   prompt.enable = cfg.enablePrompt;
      # };
    };
  }
# {
#   config,
#   host,
#   lib,
#   top,
#   lix,
#   ...
# }: let
#   dom = "system";
#   mod = "locale";
#   cfg = config.${top}.resolved.${dom}.${mod};
#   loc = host.localization;
#   inherit (lib.modules) mkIf;
#   inherit (lib.options) literalExpression mkEnableOption mkOption;
#   inherit
#     (lib.types)
#     bool
#     float
#     nullOr
#     str
#     ;
#   payload = {
#     time = {
#       inherit (cfg) timeZone;
#       hardwareClockInLocalTime = cfg.dualBootWindows;
#     };
#     location = mkIf (cfg.latitude != null && cfg.longitude != null) {
#       inherit (cfg) latitude;
#       inherit (cfg) longitude;
#       provider = cfg.locator;
#     };
#     i18n.defaultLocale = mkIf (cfg.defaultLocale != null) cfg.defaultLocale;
#   };
#   inherit (lix.modules.core.staging) mkStaged;
# in {
#   options.${top}.resolved.${dom}.${mod} = {
#     enable =
#       mkEnableOption mod
#       // {
#         default = true;
#       };
#     timeZone = mkOption {
#       description = "System timezone";
#       default = loc.timeZone;
#       defaultText = literalExpression "host.localization.timeZone";
#       type = nullOr str;
#     };
#     defaultLocale = mkOption {
#       description = "Default locale";
#       default = loc.defaultLocale;
#       defaultText = literalExpression "host.localization.defaultLocale";
#       type = nullOr str;
#     };
#     latitude = mkOption {
#       description = "Geolocation latitude";
#       default = loc.latitude;
#       defaultText = literalExpression "host.localization.latitude";
#       type = nullOr float;
#     };
#     longitude = mkOption {
#       description = "Geolocation longitude";
#       default = loc.longitude;
#       defaultText = literalExpression "host.localization.longitude";
#       type = nullOr float;
#     };
#     locator = mkOption {
#       description = "Location provider";
#       default = loc.locator;
#       defaultText = literalExpression "host.localization.locator";
#       type = str;
#     };
#     dualBootWindows = mkOption {
#       description = "Hardware clock for Windows dual-boot";
#       default = loc.dualBootWindows;
#       defaultText = literalExpression "host.localization.dualBootWindows";
#       type = bool;
#     };
#   };
#   config = lib.mkMerge (mkStaged {
#     inherit top payload;
#     condition = cfg.enable;
#   });
# }
#

