{ config, lib, ... }:
let
  inherit (lib.options) mkOption;
  inherit (lib.types) nullOr str;
  # inherit ((import ../libraries { inherit lib; }).filesystem) locateNixos locateFlake;
  inherit (config) DOTS;
  inherit (DOTS.users.alpha) name;
  inherit (DOTS.lib.filesystem) locateNixos locateFlake;

  base = "paths";
  cfg = DOTS.${base};

in
{
  options.DOTS.${base} = {
    nixos = {
      config = mkOption {
        description = "The root of the config config";
        default = locateNixos;
        type = nullOr str;
      };
      flake = mkOption {
        description = "The root of the flake config";
        default = locateFlake;
        type = nullOr str;
      };
    };
    ${name} = with cfg.${name}; {
      home = mkOption {
        description = "The current user's home directory define in env";
        default = "/home/${name}";
        type = str;
      };
      pictures = mkOption {
        default = "${home}/Pictures";
        type = str;
      };
      screenshots = mkOption {
        default = "${pictures}/Screenshots";
        type = str;
      };
      wallpapers = mkOption {
        default = "${pictures}/Wallpapers";
        type = str;
      };
      wallpaper = {
        light = mkOption {
          default = "${wallpapers}/light.jpg";
          type = str;
        };
        dark = mkOption {
          default = "${wallpapers}/dark.jpg";
          type = str;
        };
      };
    };
  };
}
