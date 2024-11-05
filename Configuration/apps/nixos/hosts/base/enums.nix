{ config, lib, ... }:
let
  #| Native Imports
  inherit (lib.options) mkOption;
  inherit (lib.types) listOf str;

  #| Extended Imports
  inherit (config) DOTS;
  base = "enums";
  mod = "host";
  src = DOTS.sources.${mod};
in
{
  options.DOTS.${base}.${mod} = {
    configuration = mkOption {
      description = "List of host configurations";
      default = src.configuration.names;
    };

    context = mkOption {
      description = "List of host types;";
      default = src.context.names;
      type = listOf str;
    };

    machine = mkOption {
      description = "List of host types;";
      default = src.machine.names;
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
          "x86_64-darwin"
          "aarch64-darwin"
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
    };
  };
}
