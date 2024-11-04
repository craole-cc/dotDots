{ config, lib, ... }:
let
  #| Native Imports
  inherit (lib.options) mkOption;
  inherit (lib.types) listOf str;

  #| Extended Imports
  inherit (config) DOTS;
  base = "enums";
  mod = "user";
  src = DOTS.sources.user;
in
{
  options.DOTS.${base}.${mod} = {
    configuration = mkOption {
      description = "{{mod}} configurations";
      default = src.configuration.names;
      type = listOf str;
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
