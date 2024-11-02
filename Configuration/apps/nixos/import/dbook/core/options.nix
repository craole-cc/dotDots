{
  config,
  lib,
  ...
}: let
  inherit (builtins) getEnv;
  inherit (lib) mkOption;
  inherit (lib.types) str float;
in {
  options.DOTS = with config.DOTS; {
    alpha = mkOption {
      description = "The default admin user";
      default = "craole";
      type = str;
    };

    stateVersion = mkOption {
      description = "The version of the OS at installation";
      default = "24.05";
      type = str;
    };

    location = {
      latitude = mkOption {
        description = "";
        default = 18.015;
        type = float;
      };
      longitude = mkOption {
        description = "";
        default = -77.5;
        type = float;
      };
      timeZone = mkOption {
        description = "";
        default = "America/Jamaica";
        type = str;
      };
      defaultLocale = mkOption {
        description = "";
        default = "en_US.UTF-8";
        type = str;
      };
    };

    paths = with paths; {
      home = mkOption {
        description = "The current user's home directory define in env";
        default = getEnv "HOME";
      };
      pictures = with pictures; {
        dir = mkOption {default = home + "/Pictures";};
        screenshots = mkOption {default = dir + "/Screenshots";};
        wallpapers = with wallpapers; {
          dir = mkOption {
            default = pictures.dir + "/Wallpapers";
          };
          light = mkOption {
            default = dir + "/light.jpg";
          };
          dark = mkOption {
            default = dir + "/dark.jpg";
          };
        };
      };
    };
  };
}
