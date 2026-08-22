{
  config,
  host,
  lix,
  names,
  paths,
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

  inherit (lix.modules.construction) mkConfig mkContext mkMerge;
  inherit (lix.lists.construction) optionals;
  inherit (lix.options.construction) literalExpression mkEnable mkOption;
  inherit
    (lix.types.combinators)
    attrsOf
    either
    listOf
    nullOr
    submodule
    ;
  inherit
    (lix.types.primitives)
    anything
    bool
    int
    ints
    path
    str
    ;
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

      flake = mkOption {
        description = ''
          Absolute path to the dotfiles flake. Used by `nh` as the flake
          reference for rebuilds and store maintenance.
        '';
        type = submodule {
          options = {
            name = mkOption {
              description = "Name identifier for the dotfiles flake.";
              default = names.flake;
              example = literalExpression ''"dots"'';
              type = str;
            };

            home = mkOption {
              description = "Local absolute path to the flake.";
              default = host.paths.flake or paths.flake.local;
              defaultText = literalExpression "host.paths.flake";
              example = literalExpression "/home/craole/.dots";
              type = str;
            };

            path = mkOption {
              description = "Nix store path to the flake.";
              default = paths.flake.store or ../../../../.;
              defaultText = literalExpression "paths.flake.store or ../../../../.";
              example = literalExpression "/nix/store/...-source";
              type = nullOr (either str path);
            };

            args = mkOption {
              description = "CLI arguments passed to flake operations.";
              default =
                {
                  inherit names;
                }
                // cfg;
              type = attrsOf anything;
            };
          };
        };
      };

      kernel = mkOption {
        description = ''
          Kernel package name. Used to auto-detect whether Nyx/Chaotic binary
          caches are required. Set to null to disable cache auto-detection.
        '';
        default = host.packages.kernel or null;
        defaultText = literalExpression "host.packages.kernel or null";
        example = literalExpression "linuxPackages_cachyos-lto";
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

      keep = {
        days = mkOption {
          description = ''
            Number of days to keep store paths during garbage collection (`--keep-since`).
            Set to `null` to disable time-based retention.
          '';
          default = 3;
          example = 7;
          type = nullOr ints.positive;
        };

        generations = mkOption {
          description = ''
            Number of recent generations to keep during garbage collection (`--keep`).
            Set to `null` to disable generation-based retention.
          '';
          default = 3;
          example = 5;
          type = nullOr ints.positive;
        };

        maxFreed = mkOption {
          description = ''
            Maximum amount of disk space (in bytes or human-readable units like `10G`)
            to free during garbage collection (`--max-freed`).
            Set to `null` to disable maximum freed size limits.
          '';
          default = null;
          example = "10G";
          type = nullOr str;
        };

        args = mkOption {
          description = ''
            CLI arguments passed to `nix store gc`. Defaults to flags built from
            `keep.days`, `keep.generations`, and `keep.maxFreed`.
          '';
          default =
            (optionals (cfg.keep.days != null) [
              "--keep-since"
              "${toString cfg.keep.days}d"
            ])
            ++ (optionals (cfg.keep.generations != null) [
              "--keep"
              "${toString cfg.keep.generations}"
            ])
            ++ (optionals (cfg.keep.maxFreed != null) [
              "--max-freed"
              cfg.keep.maxFreed
            ]);
          defaultText = literalExpression ''
            (optionals (cfg.keep.days != null) ["--keep-since" "''${toString cfg.keep.days}d"])
            ++ (optionals (cfg.keep.generations != null) ["--keep" "''${toString cfg.keep.generations}"])
            ++ (optionals (cfg.keep.maxFreed != null) ["--max-freed" cfg.keep.maxFreed])
          '';
          example = [
            "--keep-since"
            "7d"
            "--keep"
            "5"
            "--max-freed"
            "10G"
          ];
          type = listOf str;
        };
      };
    };

    outputs = mkMerge [
      (mkNix {
        inherit host pkgs;
        inherit
          (cfg)
          flake
          kernel
          caches
          max-jobs
          stateVersion
          ;
        store = tree.store.default;
      })
      (mkMaintenance {
        inherit pkgs paths;
        inherit (cfg) flake keep;
      })
    ];
  }
