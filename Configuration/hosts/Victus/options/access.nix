{lib, ...}: let
  inherit (lib.options) mkOption mkEnableOption;
  inherit
    (lib.types)
    listOf
    str
    submodule
    int
    ;
in
  mkOption {
    description = "Access and security options including keys and firewall configuration";
    default = {};
    type = submodule {
      options = {
        ssh = mkOption {
          description = "SSH public key string for authentication";
          default = "";
          type = str;
        };

        age = mkOption {
          description = "AGE encryption public key string";
          default = "";
          type = str;
        };

        firewall = mkOption {
          description = "Firewall rule sets and enable flag";
          default = {};
          type = submodule {
            options = {
              enable = mkEnableOption "Firewall";
              tcp = mkOption {
                description = "TCP firewall port ranges and specific ports allowed";
                default = {};
                example = {
                  ranges = [
                    {
                      from = 49160;
                      to = 65534;
                    }
                  ];
                  ports = [
                    22
                    80
                    443
                  ];
                };
                type = submodule {
                  options = {
                    ranges = mkOption {
                      description = "TCP port ranges";
                      default = [];
                      type = listOf (submodule {
                        options = {
                          from = mkOption {
                            type = int;
                            description = "Start port";
                            default = 0;
                          };
                          to = mkOption {
                            type = int;
                            description = "End port";
                            default = 0;
                          };
                        };
                      });
                    };

                    ports = mkOption {
                      description = "TCP ports";
                      default = [];
                      type = listOf int;
                    };
                  };
                };
              };

              udp = mkOption {
                description = "UDP firewall port ranges and specific ports allowed";
                default = {};
                example = {
                  ranges = [
                    {
                      from = 49160;
                      to = 65534;
                    }
                  ];
                  ports = [
                    22
                    80
                    443
                  ];
                };
                type = submodule {
                  options = {
                    ranges = mkOption {
                      description = "UDP port ranges";
                      default = [];
                      type = listOf (submodule {
                        options = {
                          from = mkOption {
                            type = int;
                            description = "Start port";
                            default = 0;
                          };
                          to = mkOption {
                            type = int;
                            description = "End port";
                            default = 0;
                          };
                        };
                      });
                    };

                    ports = mkOption {
                      description = "UDP ports";
                      default = [];
                      type = listOf int;
                    };
                  };
                };
              };
            };
          };
        };

        nameservers = mkOption {
          description = "DNS IP addresses";
          default = [];
          example = [
            "1.1.1.1"
            "1.0.0.1"
          ];
          type = listOf str;
        };
      };
    };
  }
