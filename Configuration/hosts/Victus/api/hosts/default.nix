{
  lix,
  lib,
  name,
  ...
}: let
  mod = "hosts";
  # cfg = config.${mod};

  inherit (lib.attrsets) attrByPath;
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.strings) substring;
  inherit (builtins) hashString;
  inherit
    (lib.types)
    nullOr
    oneOf
    either
    int
    str
    float
    listOf
    enum
    submodule
    attrsOf
    ;
  inherit
    (lix.enums)
    hostFunctionalities
    cpuBrands
    cpuPowerModes
    gpuBrands
    ;

  opt = {
    name,
    config,
    ...
  }: {
    options = {
      enable = mkEnableOption name;

      id = mkOption {
        description = "Unique identifier string for the host; auto-generated from hash of the current file";
        default = let
          uuid = attrByPath ["devices" "file" "/" "device"] name cfg;
        in
          substring 0 8 (hashString "md5" uuid);
        type = str;
      };

      stateVersion = mkOption {
        description = ''
          OS release version at install time, essential for compatibility
          You may find the correct value at the end of your system's config in /etc/nixos/configuration.nix.
          Typical values look like "25.05" or "24.11".
        '';
        default = null;
        type = nullOr str;
      };

      functionalities = mkOption {
        description = "List of system functionalities for hardware and functionality";
        default = [];
        type = listOf (enum hostFunctionalities.enum);
      };

      modules = mkOption {
        description = "Initrd modules";
        default = [];
        type = listOf str;
      };

      specs = mkOption {
        description = "Hardware specifications for machine type, CPU/GPU details, and platform arch";
        default = {};
        type = submodule {
          options = {
            machine = mkOption {
              description = "General base machine category to infer defaults or enable hardware-specific options";
              default = "laptop";
              type = enum [
                "laptop"
                "desktop"
                "server"
                "raspberry"
              ];
            };

            platform = mkOption {
              description = "Targeted platform for software compatibility and architecture-specific packages";
              default = "";
              example = "x86_64-linux";
              type = enum [
                "x86_64-linux"
                "aarch64-linux"
              ];
            };

            system = mkOption {
              default = "${cfg.specs.platform}";
              type = str;
            };

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
          };
        };
      };

      devices = mkOption {
        description = "Device configuration for boot, file systems, swap, and network interfaces";
        default = {};
        type = submodule {
          options = {
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

            display = mkOption {
              description = "Display/monitor configuration";
              default = [];
              type = listOf (submodule {
                options = {
                  name = mkOption {
                    description = "Monitor name (e.g., eDP-1, DP-1) or empty string for any monitor";
                    default = "";
                    type = str;
                  };
                  resolution = mkOption {
                    description = "Display resolution (e.g., 1920x1080) or 'preferred'";
                    type = str;
                    default = "preferred";
                  };
                  refreshRate = mkOption {
                    description = "Refresh rate in Hz or 'preferred'";
                    default = "preferred";
                    type = oneOf [
                      int
                      float
                      str
                    ];
                  };
                  scale = mkOption {
                    description = "Display scale factor";
                    default = 1.0;
                    type = either float int;
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
      };
    };
  };
in {
  options.${mod} = mkOption {
    description = "All host configuration options";
    default = {};
    type = attrsOf (
      submodule {
      }
    );
  };
}
