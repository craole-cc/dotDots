{ args, ... }:
let
  inherit (args) lib;
in
let
  inherit (lib.options) mkOption;
  inherit (lib.types)
    submodule
    attrsOf
    str
    listOf
    float
    ;
in
mkOption {
  description = "Device configuration for boot, file systems, swap, network interfaces, and displays";
  default = { };
  type = submodule {
    options = {
      boot = mkOption {
        description = "LUKS or other encrypted boot devices keyed on device names";
        default = { };
        type = attrsOf (submodule {
          options = {
            device = mkOption {
              description = "Device path or UUID for boot device (like LUKS)";
              type = str;
            };
          };
        });
      };

      file = mkOption {
        description = "Filesystem mount points with device, filesystem type, and mount options";
        default = { };
        type = attrsOf (submodule {
          options = {
            device = mkOption {
              description = "Block device or UUID for file system";
              type = str;
            };
            fsType = mkOption {
              description = "File system type (ext4, vfat, etc.)";
              type = str;
            };
            options = mkOption {
              description = "Mount options";
              type = listOf str;
              default = [ ];
            };
          };
        });
      };

      swap = mkOption {
        description = "Swap devices configured as a list with device UUIDs or paths";
        default = [ ];
        type = listOf (submodule {
          options = {
            device = mkOption {
              description = "Swap device path or UUID";
              type = str;
            };
          };
        });
      };

      network = mkOption {
        description = "Network interface names, typically system interface identifiers";
        default = [ ];
        type = listOf str;
      };

      display = mkOption {
        description = "Display/monitor configuration";
        default = [ ];
        type = listOf (submodule {
          options = {
            name = mkOption {
              description = "Monitor name (e.g., eDP-1, DP-1) or empty string for any monitor";
              type = str;
              default = "";
            };
            resolution = mkOption {
              description = "Display resolution (e.g., 1920x1080) or 'preferred'";
              type = str;
              default = "preferred";
            };
            refreshRate = mkOption {
              description = "Refresh rate in Hz or 'preferred'";
              type = str;
              default = "preferred";
            };
            scale = mkOption {
              description = "Display scale factor";
              type = float;
              default = 1.0;
            };
            position = mkOption {
              description = "Display position (e.g., 0x0, 1920x0) or 'auto'";
              type = str;
              default = "auto";
            };
          };
        });
      };
    };
  };
}
