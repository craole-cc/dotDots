{
  config,
  host,
  lix,
  pkgs,
  tree,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "system";
    mod = "nix";
  };
  inherit (context) cfg;

  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) literalExpression mkEnable mkOption;
  inherit (lix.types.combinators) attrsOf either nullOr submodule;
  inherit (lix.types.primitives) bool int str;
  inherit (lix.modules.core.software) mkNix mkMaintenance;
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {
        inherit context;
        condition = host.hardware.hasBluetooth;
      };

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
    outputs = lix.modules.construction.mkMerge [
      (mkNix {
        inherit host pkgs;
        inherit (cfg) kernel caches max-jobs stateVersion;
        store = tree.store.default;
      })
      (mkMaintenance {
        inherit (host.paths) src;
        inherit pkgs;
      })
    ];
  }
