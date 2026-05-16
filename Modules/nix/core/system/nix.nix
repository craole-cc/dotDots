{
  config,
  host,
  lib,
  lix,
  pkgs,
  top,
  tree,
  ...
}: let
  dom = "system";
  mod = "nix";
  cfg = config.${top}.${dom}.${mod};

  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.options) literalExpression mkEnableOption mkOption;
  inherit (lib.types) attrsOf bool either int nullOr str submodule;
  inherit (lix.modules.core.software) mkNix mkMaintenance;
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption mod // {default = true;};

    stateVersion = mkOption {
      description = ''
        The NixOS state version for this host. Set this to the NixOS version
        that was active when the system was first installed and never change it.
        Changing this value may break stateful services.
      '';
      default = host.stateVersion;
      defaultText = literalExpression "host.stateVersion";
      example = literalExpression ''"25.11"'';
      type = str;
    };

    system = mkOption {
      description = ''
        The target system architecture triple for this host.
      '';
      default = host.system;
      defaultText = literalExpression "host.system";
      example = literalExpression ''"x86_64-linux"'';
      type = str;
    };

    dots = mkOption {
      description = ''
        Absolute path to the dotfiles flake. Used by `nh` as the flake
        reference for rebuilds and store maintenance.
      '';
      default = host.paths.dots;
      defaultText = literalExpression "host.paths.dots";
      example = literalExpression ''/home/craole/.dots'';
      type = str;
    };

    kernel = mkOption {
      description = ''
        Kernel package name. Used to auto-detect whether Nyx/Chaotic binary
        caches are required. Set to null to disable cache auto-detection.
      '';
      default = host.packages.kernel or null;
      defaultText = literalExpression "host.packages.kernel or null";
      example = literalExpression ''linuxPackages_cachyos-lto'';
      type = nullOr str;
    };

    max-jobs = mkOption {
      description = ''
        Maximum number of concurrent Nix build jobs. Set to "auto" to use
        all available cores.
      '';
      default = host.specs.cpu.cores or "auto";
      defaultText = literalExpression ''host.specs.cpu.cores or "auto"'';
      example = literalExpression "12";
      type = either int str;
    };

    caches = mkOption {
      description = ''
        Binary cache overrides merged over auto-detected defaults. Each entry
        requires a substituter URL and a trusted public key. Set `enable =
        false` on any entry to exclude it.
      '';
      default = host.caches or {};
      defaultText = literalExpression "host.caches or {}";
      example = literalExpression ''
        {
          nyx = {
            sub = "https://geo-mirror.chaotic.cx/";
            key = "nyx.chaotic.cx-1:CNZOSlPJO5F0utqsPzkZbHkkD7YzNDWHGG6PqS30wMc=";
          };
        }
      '';
      type = attrsOf (submodule {
        options = {
          enable = mkOption {
            description = "Whether to include this cache.";
            type = bool;
            default = true;
          };
          sub = mkOption {
            description = "Substituter URL.";
            example = literalExpression ''"https://cache.numtide.com"'';
            type = str;
          };
          key = mkOption {
            description = "Trusted public key.";
            example = literalExpression ''"cache.numtide.com-1:dGZlQILjUw6nfhbyU3aRjVm4iklknCKEIh5+OR2TXVY="'';
            type = str;
          };
        };
      });
    };
  };

  config = mkIf cfg.enable (
    mkMerge [
      (mkNix {
        inherit host pkgs tree;
        inherit (cfg) kernel caches max-jobs stateVersion;
      })
      (mkMaintenance {
        inherit (cfg) dots;
        inherit pkgs;
      })
    ]
  );
}
