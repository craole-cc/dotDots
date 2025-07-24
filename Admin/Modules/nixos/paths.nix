{
  config,
  lib,
  ...
}: let
  inherit (lib.options) mkOption;
  # inherit (lib.strings) toUpper;
  inherit
    (lib.types)
    # attrs
    # attrsOf
    either
    str
    path
    ;

  dom = "DOTS";
  mod = "paths";
  cfg = config.${dom}.${mod};
in {
  options.${dom}.${mod} = {
    base = mkOption {
      description = "Path to the dots repository.";
      default = "/home/craole/.dots";
      type = either str path;
    };
    scripts = mkOption {
      description = "Path to the dots bin directory.";
      default = "${cfg.base}/Bin";
      type = either str path;
    };
    configuration = mkOption {
      description = "Path to the dots configuration directory.";
      default = "${cfg.base}/Configuration";
      type = either str path;
    };
    conf = {
      base = mkOption {
        description = "Path to the dots configuration directory.";
        default = cfg.configuration;
        type = either str path;
      };
      hosts = mkOption {
        description = "Path to the dots hosts configuration directory.";
        default = "${cfg.conf.base}/hosts";
        type = either str path;
      };
      users = mkOption {
        description = "Path to the dots users configuration directory.";
        default = "${cfg.conf.base}/users";
        type = either str path;
      };
    };
    documentation = mkOption {
      description = "Path to the dots documentation.";
      default = "${cfg.base}/Documentation";
      type = either str path;
    };
    environment = mkOption {
      description = "Path to the dots environment.";
      default = "${cfg.base}/Environment";
      type = either str path;
    };
    libraries = mkOption {
      description = "Path to the dots libraries directory.";
      default = "${cfg.base}/Libraries";
      type = either str path;
    };
    lib = {
      base = mkOption {
        description = "Path to the dots libraries directory.";
        default = cfg.libraries;
        type = either str path;
      };
      admin = {
        base = mkOption {
          description = "Path to the admin libraries directory.";
          default = "${cfg.lib.base}/admin";
          type = either str path;
        };
        mkHost = mkOption {
          description = "Path to the mkHost script.";
          default = "${cfg.lib.admin.base}/mkHost.nix";
          type = either str path;
        };
        mkModules = mkOption {
          description = "Path to the mkModules script.";
          default = "${cfg.libraries}/admin/mkModules.nix";
          type = either str path;
        };
        mkPackages = mkOption {
          description = "Path to the mkPackages script.";
          default = "${cfg.libraries}/admin/mkPackages.nix";
          type = either str path;
        };
      };
      core = mkOption {
        description = "Path to the core libraries directory.";
        default = "${cfg.libraries}/core";
        type = either str path;
      };
      mkHost = mkOption {
        description = "Path to the mkHost script.";
        default = cfg.lib.admin.mkHost;
        type = either str path;
      };
      mkModules = mkOption {
        description = "Path to the mkModules script.";
        default = cfg.lib.admin.mkModules;
        type = either str path;
      };
      mkPackages = mkOption {
        description = "Path to the mkPackages script.";
        default = cfg.lib.admin.mkPackages;
        type = either str path;
      };
    };
    modules = mkOption {
      description = "Path to the dots modules directory.";
      default = "${cfg.base}/Modules";
      type = either str path;
    };
    mod = {
      base = mkOption {
        description = "Path to the dots modules directory.";
        default = cfg.modules;
        type = either str path;
      };
    };
    hosts = mkOption {
      description = "Path to the hosts configuration directory.";
      default = "${cfg.configuration}/hosts";
      type = either str path;
    };
    users = mkOption {
      description = "Path to the users configuration directory.";
      default = "${cfg.configuration}/users";
      type = either str path;
    };
    passwords = mkOption {
      description = "Path to the password directory.";
      default = "/var/lib/dots/passwords";
      type = either str path;
    };
    packages = mkOption {
      description = "Path to the packages directory.";
      default = "${cfg.base}/Packages";
      type = either str path;
    };
    pkgs = {
      base = mkOption {
        description = "Path to the packages directory.";
        default = cfg.packages;
        type = either str path;
      };
      core = mkOption {
        description = "Path to the core packages directory.";
        default = "${cfg.pkgs.base}/core";
        type = either str path;
      };
      custom = mkOption {
        description = "Path to the custom packages directory.";
        default = "${cfg.pkgs.base}/custom";
        type = either str path;
      };
      overlays = mkOption {
        description = "Path to the overlays packages directory.";
        default = "${cfg.pkgs.base}/overlays";
        type = either str path;
      };
      home = mkOption {
        description = "Path to the home packages directory.";
        default = "${cfg.pkgs.base}/home";
        type = either str path;
      };
    };
  };

  # config.environment.variables.DOTS = cfg.base;
}
