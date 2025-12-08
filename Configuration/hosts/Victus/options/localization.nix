{ args }:
let
  inherit (args) lib;
  inherit (lib.options) mkOption;
  inherit (lib.types)
    nullOr
    str
    enum
    submodule
    float
    ;
in
mkOption {
  description = "Geographical location details used for timezone and localization";
  default = { };
  type = submodule {
    options = {
      latitude = mkOption {
        description = "Latitude coordinate";
        default = null;
        type = nullOr float;
      };

      longitude = mkOption {
        description = "Longitude coordinate";
        default = null;
        type = nullOr float;
      };

      provider = mkOption {
        description = "Location provider for time zone determination";
        default = "geoclue2";
        type = enum [
          "geoclue2"
          "manual"
        ];
      };

      timeZone = mkOption {
        description = "Time zone identifier";
        default = null;
        type = nullOr str;
      };

      defaultLocale = mkOption {
        description = "Default locale string";
        type = str;
        default = "en_US.UTF-8";
      };
    };
  };
}
