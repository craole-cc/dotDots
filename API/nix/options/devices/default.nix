{lix, ...}: let
  inherit (lix.std.options) mkOption;
  inherit
    (lix.std.types)
    nullOr
    either
    int
    str
    listOf
    enum
    submodule
    attrsOf
    ;
  inherit
    (lix.enums)
    cpuBrands
    cpuPowerModes
    gpuBrands
    ;
in {
  devices = mkOption {
    description = "Device configuration for boot, file systems, swap, and network interfaces";
    default = {};
    type = submodule {
      options =
        {
          cpu = mkOption {
            description = "CPU vendor and behaviour settings";
            default = {};
            type = submodule {
              options = {
                cores = mkOption {
                  type = either int (enum ["auto"]);
                  default = "auto";
                  example = 64;
                  description = ''
                    This option defines the maximum number of jobs that Nix will try to
                    build in parallel. The default is auto, which means it will use all
                    available logical cores. It is recommend to set it to the total
                    number of logical cores in your system (e.g., 16 for two CPUs with 4
                    cores each and hyper-threading).
                  '';
                };
                brand = mkOption {
                  description = "CPU brand";
                  default = null;
                  type = nullOr (enum cpuBrands.enum);
                };
                arch = mkOption {
                  description = "CPU architecture";
                  default = "x86_64";
                  type = enum [
                    "x86_64"
                    "aarch64"
                  ];
                };
                powerMode = mkOption {
                  description = "CPU operating mode";
                  default = "performance";
                  type = enum cpuPowerModes.enum;
                };
              };
            };
          };

          gpu = mkOption {
            description = "GPU configuration - can be single or hybrid setup";
            default = {};
            type = submodule {
              options = {
                mode = mkOption {
                  description = "GPU operation mode";
                  default = "single";
                  type = enum [
                    "single"
                    "hybrid"
                    "offload"
                    "sync"
                  ];
                };

                primary = mkOption {
                  description = "Primary GPU (used for display)";
                  default = null;
                  type = nullOr (submodule {
                    options = {
                      brand = mkOption {
                        type = nullOr (enum gpuBrands.enum);
                      };
                      busId = mkOption {
                        description = "PCI bus ID in format 'PCI:X:Y:Z'";
                        type = str;
                        example = "PCI:6:0:0";
                      };
                      model = mkOption {
                        type = str;
                        default = "";
                      };
                    };
                  });
                };

                secondary = mkOption {
                  description = "Secondary GPU (for offload/hybrid)";
                  default = null;
                  type = nullOr (submodule {
                    options = {
                      brand = mkOption {
                        type = nullOr (enum gpuBrands.enum);
                      };
                      busId = mkOption {
                        description = "PCI bus ID in format 'PCI:X:Y:Z'";
                        type = str;
                        example = "PCI:1:0:0";
                      };
                      model = mkOption {
                        type = str;
                        default = "";
                      };
                    };
                  });
                };
              };
            };
          };

          boot = mkOption {
            description = "LUKS or other encrypted boot devices keyed on device names";
            default = {};
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
            default = {};
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
                  default = [];
                };
              };
            });
          };

          swap = mkOption {
            description = "Swap devices configured as a list with device UUIDs or paths";
            default = [];
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
            default = [];
            type = listOf str;
          };
        }
        // import ./displays.nix;
    };
  };
}
