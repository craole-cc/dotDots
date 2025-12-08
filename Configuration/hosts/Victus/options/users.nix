{
  lix,
  lib,
  ...
}: let
  passwordDir = "/var/lib/nixos/passwords";

  inherit (lib.options) mkOption mkEnableOption;
  inherit
    (lib.types)
    attrsOf
    listOf
    nullOr
    passwdEntry
    enum
    # attrs
    either
    path
    str
    submodule
    anything
    ;
  inherit (lix.enums) userCapabilities userRoles shells;
in {
  people = mkOption {
    description = "User account names applicable to this host";
    default = [];
    type = listOf str;
  };

  users = mkOption {
    description = "User account definitions based on people";
    default = {};
    type = attrsOf anything; # TODO: This should not be of anything but of a user, defined in allUsers
  };

  allUsers = mkOption {
    description = "Users configuration";
    default = {};
    type = attrsOf (submodule {
      options = {
        enable = mkEnableOption "User";
        autoLogin = mkEnableOption "autologin";

        role = mkOption {
          description = "Contexts describing usage scenario categories for the host";
          default = "service";
          type = enum userRoles.enum;
        };

        capabilities = mkOption {
          description = "Contexts describing usage scenario categories for the host";
          default = [];
          type = listOf (enum userCapabilities.enum);
        };

        groups = mkOption {
          description = "Additional user groups";
          default = [];
          type = listOf str;
        };

        description = mkOption {
          description = "User description";
          default = null;
          type = nullOr str;
        };

        password = mkOption {
          description = ''Specifies the hashed password for the user.'';
          default = null;
          type = nullOr (passwdEntry str);
        };

        passwordFile = mkOption {
          description = lib.mdDoc ''
            Path to a per-user hashed password file stored under:
            `${passwordDir}/<username>`
          '';
          default = null;
          type = nullOr str;
        };

        shells = mkOption {
          description = "Shells";
          default = [];
          type = listOf (enum shells.enum);
        };

        git = mkOption {
          description = "Per-user Git identity (used by Home Manager or programs.git).";
          default = {};
          type = submodule {
            options = {
              name = mkOption {
                description = "Default Git user.name for this user.";
                default = null;
                type = nullOr str;
              };

              email = mkOption {
                description = "Default Git user.email for this user.";
                default = null;
                type = nullOr str;
              };

              signingKey = mkOption {
                description = "GPG signing key ID for this user's Git commits.";
                default = null;
                type = nullOr str;
              };
            };
          };
        };

        applications = mkOption {
          description = "Per-user application preferences";
          default = {};
          type = submodule {
            options = {
              browser = mkOption {
                description = "Web browser preferences";
                default = {};
                type = submodule {
                  options = {
                    primary = mkOption {
                      description = "Primary web browser";
                      default = null;
                      type = nullOr str;
                    };

                    secondary = mkOption {
                      description = "Secondary web browser";
                      default = null;
                      type = nullOr str;
                    };

                    firefox = mkOption {
                      description = "Firefox variant (e.g., zen, librewolf, firefox)";
                      default = null;
                      type = nullOr str;
                    };

                    chromium = mkOption {
                      description = "Chromium variant (e.g., edge, chrome, brave, vivaldi)";
                      default = null;
                      type = nullOr str;
                    };
                  };
                };
              };

              editor = mkOption {
                description = "Text editor preferences";
                default = {};
                type = submodule {
                  options = {
                    tty = mkOption {
                      description = "Terminal-based editors";
                      default = {};
                      type = submodule {
                        options = {
                          primary = mkOption {
                            description = "Primary terminal editor";
                            default = null;
                            type = nullOr str;
                          };

                          secondary = mkOption {
                            description = "Secondary terminal editor";
                            default = null;
                            type = nullOr str;
                          };
                        };
                      };
                    };

                    gui = mkOption {
                      description = "GUI-based editors";
                      default = {};
                      type = submodule {
                        options = {
                          visual = mkOption {
                            description = "Visual GUI editor";
                            default = null;
                            type = nullOr str;
                          };

                          sudo = mkOption {
                            description = "Editor for privileged operations";
                            default = null;
                            type = nullOr str;
                          };
                        };
                      };
                    };
                  };
                };
              };

              terminal = mkOption {
                description = "Terminal emulator preferences";
                default = {};
                type = submodule {
                  options = {
                    primary = mkOption {
                      description = "Primary terminal emulator";
                      default = null;
                      type = nullOr str;
                    };

                    secondary = mkOption {
                      description = "Secondary terminal emulator";
                      default = null;
                      type = nullOr str;
                    };
                  };
                };
              };

              launcher = mkOption {
                description = "Application launcher preferences";
                default = {};
                type = submodule {
                  options = {
                    primary = mkOption {
                      description = "Primary application launcher";
                      default = null;
                      type = nullOr str;
                    };

                    secondary = mkOption {
                      description = "Secondary application launcher";
                      default = null;
                      type = nullOr str;
                    };
                  };
                };
              };
            };
          };
        };

        paths = mkOption {
          default = {};
          type = attrsOf (either str path);
        };
      };
    });
  };
}
