{ lib, ... }:
let
  inherit (lib.options) mkOption;
  inherit (lib.types) str float nullOr;
in
{
  options.DOTS.location = {
    timeZone = mkOption {
      description = "The time zone used for displaying time and dates.";
      default = "America/Jamaica";
      type = nullOr str;
    };

    latitude = mkOption {
      description = "The latitudinal coordinate as a decimal between `-90.0` and `90.0`";
      default = 18.015;
      type = float;
    };

    longitude = mkOption {
      description = "The longitudinal coordinate as a decimal between `-180.0` and `180.0`";
      default = -77.5;
      type = float;
    };

    defaultLocale = mkOption {
      description = "The default locale for the system";
      default = "en_US.UTF-8";
      type = str;
    };
  };
}
