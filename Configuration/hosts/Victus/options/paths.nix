{ args }:
let
  inherit (args)
    cfg
    name
    lix
    lib
    ;
  inherit (lib.options) mkOption;
  inherit (lib.attrsets) attrByPath mapAttrs;
  inherit (lib.strings) isString;
  inherit (lib.types) attrsOf submodule;
  inherit (lix.path)
    flexPath
    mkFlexPath
    mkPathGroup
    mkDerivedPath
    ;
  base = attrByPath [ "paths" "base" ] { } cfg;
  default = {
    base = {
      relative = "../../..";
      absolute = "/etc/nixos";
    };
  };
in
mkOption {
  inherit default;
  description = "Path configuration for the ${name} environment";
  type = submodule {
    options = {
      # ============================================================
      # BASE PATH - Foundation for all derived paths
      # ============================================================
      base = mkFlexPath "Repository root directory - reference point for all repo-relative paths" {
        # relative = "../../..";
        # absolute = "/etc/nixos";
        inherit (default.base) relative absolute;
      };

      # ============================================================
      # API PATHS - Grouped with descriptions
      # ============================================================
      api = mkPathGroup "API configuration paths for hosts and users" {
        base = mkDerivedPath {
          inherit base;
          stem = "api";
          desc = "Root directory for API-related configurations";
        };

        host = mkDerivedPath {
          inherit base;
          stem = [
            "api"
            "hosts"
            name
          ];
          desc = "Host-specific API configuration for ${name}";
        };

        hosts = mkDerivedPath {
          inherit base;
          stem = [
            "api"
            "hosts"
          ];
          desc = "All host API configurations";
        };

        users = mkDerivedPath {
          inherit base;
          stem = [
            "api"
            "users"
          ];
          desc = "All user API configurations";
        };
      };
      # ============================================================
      # BINARY PATHS
      # ============================================================
      binaries = mkPathGroup "Binary script directories organized by shell type" {
        base = mkDerivedPath {
          inherit base;
          stem = "bin";
          desc = "Root directory for binary scripts";
        };

        bash = mkDerivedPath {
          inherit base;
          stem = [
            "bin"
            "bourneshell"
          ];
          desc = "Bash/Bourne shell scripts";
        };

        nushell = mkDerivedPath {
          inherit base;
          stem = [
            "bin"
            "nushell"
          ];
        };

        pwsh = mkDerivedPath {
          inherit base;
          stem = [
            "bin"
            "powershell"
          ];
        };

        sh = mkDerivedPath {
          inherit base;
          stem = [
            "bin"
            "shellscript"
          ];
        };
      };
      # ============================================================
      # CACHE, LIBRARIES, LOG PATHS (single-path groups)
      # ============================================================
      cache = mkPathGroup "Cache directory" {
        base = mkDerivedPath {
          inherit base;
          stem = "tmp";
        };
      };

      log = mkPathGroup "Log files directory" {
        base = mkDerivedPath {
          inherit base;
          stem = "log";
        };
      };

      libraries = mkPathGroup "Library files directory" {
        base = mkDerivedPath {
          inherit base;
          stem = "lib";
        };
      };
      # ============================================================
      # MODULE PATHS
      # ============================================================
      modules = mkPathGroup "NixOS module directories" {
        base = mkDerivedPath {
          inherit base;
          stem = "modules";
        };

        core = mkDerivedPath {
          inherit base;
          stem = [
            "modules"
            "core"
          ];
        };

        packages = mkDerivedPath {
          inherit base;
          stem = [
            "modules"
            "package"
          ];
        };

        services = mkDerivedPath {
          inherit base;
          stem = [
            "modules"
            "service"
          ];
        };
      };
      # ============================================================
      # PACKAGE PATHS
      # ============================================================
      packages = mkPathGroup "Package configuration directories" {
        base = mkDerivedPath {
          inherit base;
          stem = [
            "modules"
            "package"
          ];
        };

        home = mkDerivedPath {
          inherit base;
          stem = [
            "modules"
            "package"
            "home"
          ];
        };

        core = mkDerivedPath {
          inherit base;
          stem = [
            "modules"
            "package"
            "core"
          ];
        };
      };
      # ============================================================
      # SERVICE PATHS
      # ============================================================
      services = mkPathGroup "Service configuration directories" {
        base = mkDerivedPath {
          inherit base;
          stem = [
            "modules"
            "service"
          ];
        };

        home = mkDerivedPath {
          inherit base;
          stem = [
            "modules"
            "service"
            "home"
          ];
        };

        core = mkDerivedPath {
          inherit base;
          stem = [
            "modules"
            "service"
            "core"
          ];
        };
      };
      # ============================================================
      # OPTION PATHS
      # ============================================================
      options = mkPathGroup "Option definition directories" {
        base = mkDerivedPath {
          inherit base;
          stem = "options";
        };

        home = mkDerivedPath {
          inherit base;
          stem = [
            "options"
            "home"
          ];
        };

        core = mkDerivedPath {
          inherit base;
          stem = [
            "options"
            "core"
          ];
        };

        common = mkDerivedPath {
          inherit base;
          stem = [
            "options"
            "shared"
          ];
        };
      };
      # ============================================================
      # EXTRA/CUSTOM PATHS
      # ============================================================
      extra = mkOption {
        description = ''
          Additional flexible paths specific to this host.
          Can be set as simple strings (absolute only) or with relative paths.

          Examples:
            extra.videos = "/home/user/Videos";
            extra.backup = { relative = "../../backup"; absolute = "/mnt/backup"; };
        '';
        type = attrsOf flexPath;
        default = { };
        apply = mapAttrs (
          name: val:
          if isString val then
            {
              relative = null;
              absolute = val;
            }
          else
            val
        );
      };
    };
  };
}
