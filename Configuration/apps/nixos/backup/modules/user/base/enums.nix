{ config, lib, ... }:
let
  inherit (lib.options) mkOption;
  inherit (lib.types) listOf str;

  src = config.dot.sources.user;
in
{
  options.dot.enums.user = with config.dot.enums.user; {
    configuration = mkOption {
      description = "List of user configurations";
      default = src.configuration.names;
    };

    context = mkOption {
      description = "List of user types;";
      default = src.context.names;
      type = listOf str;
    };

    desktop = {
      manager = mkOption {
        description = "List of desktop managers";
        default = [
          "hyprland"
          # "gnome"
          # "plasma"
        ]; # TODO: get from source
        type = listOf str;
      };

      server = mkOption {
        description = "List of desktop managers";
        default = [
          "wayland"
          "x11"
        ];
        type = listOf str;
      };
    };

    display = {
      manager = mkOption {
        description = "List of login managers";
        example = "systemd";
        default = [
          "sddm"
          "kmscon"
          "greetd"
          "lightdm"
          "gdm"
        ]; # TODO: get from source
        type = listOf str;
      };
    };
  };
}
