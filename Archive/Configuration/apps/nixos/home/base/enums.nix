{ config, lib, ... }:
let
  #| Native Imports
  inherit (lib.options) mkOption;
  inherit (lib.types) listOf str;

  #| Extended Imports
  inherit (config) DOTS;
  base = "enums";
  mod = "user";
  src = DOTS.sources.${mod};
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

    manager = {
      desktop = mkOption {
        description = "List of desktop managers";
        default = [
          "hyprland"
          # "gnome"
          # "plasma"
        ]; # TODO: get from source
        type = listOf str;
      };

      protocol = mkOption {
        description = "List of desktop managers";
        default = [
          "wayland"
          "x11"
        ];
        type = listOf str;
      };
    };
  };
}
