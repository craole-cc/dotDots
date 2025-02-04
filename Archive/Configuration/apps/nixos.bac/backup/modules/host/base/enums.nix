{ config, lib, ... }:
let
  inherit (lib.options) mkOption;
  inherit (lib.types) listOf str;

  src = config.dot.sources.host;
in
{
  options.dot.enums.host = with config.dot.enums.host; {
    configuration = mkOption {
      description = "List of host configurations";
      default = src.configuration.names;
    };

    machine = mkOption {
      description = "List of host types;";
      default = src.machine.names;
      type = listOf str;
    };

    context = mkOption {
      description = "List of host types;";
      default = src.context.names;
      type = listOf str;
    };

    processor = {
      cpu = mkOption {
        description = "List of CPU types";
        default = [
          "intel"
          "amd"
        ];
        type = listOf str;
      };

      arch = mkOption {
        description = "List of platform types";
        default = [
          "x86_64-linux"
          "aarch64-linux"
        ];
        type = listOf str;
      };

      mode = mkOption {
        description = "List of platform types";
        default = [
          "powersave"
          "ondemand"
          "performance"
        ];
        type = listOf str;
      };

      gpu = mkOption {
        description = "List of GPU types";
        example = "intel";
        default = processor.cpu ++ [ "nvidia" ];
        type = listOf str;
      };
    };

    manager = {

      boot = mkOption {
        description = "List of boot manager types";
        example = "systemd";
        default = [
          "systemd"
          "grub"
        ];
        type = listOf str;
      };

      display = mkOption {
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

      desktop = mkOption {
        description = "List of desktop managers";
        example = "gnome";
        default = [
          "hyprland"
          # "gnome"
          # "plasma"
        ]; # TODO: get from source
        type = listOf str;
      };

      server = mkOption {
        description = "List of desktop managers";
        example = "gnome";
        default = [
          "hyprland"
          # "gnome"
          # "plasma"
        ]; # TODO: get from source
        type = listOf str;
      };
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
  };
}
