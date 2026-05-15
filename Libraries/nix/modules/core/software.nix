{_, ...}: let
  meta = let
    doc = ''
      # Core Software [Layer 3]

      NixOS system configuration builders for core software concerns.

      Provides `mkNix` for declarative Nix daemon configuration - including
      binary cache auto-detection, experimental features, and file descriptor
      limits - and `mkMaintenance` for automated store maintenance via `nh`
      with convenience shell aliases.

      ## Cache Resolution

      `mkNix` resolves binary caches in two layers:

      - `common`: auto-detected from the flake lock file and kernel selection.
        Numtide is injected when any input is owned by `numtide`. Nyx/Chaotic
        is injected when a CachyOS kernel is requested.
      - `custom`: declared in `host.caches`, merged over `common` via
        `recursiveUpdate` so per-host overrides win.

      Entries with `enable = false` are filtered out before use.

      ## Maintenance

      `mkMaintenance` enables `nh clean` on a timer with a retention policy
      of 3 days or 5 generations, whichever is greater. It also exposes shell
      aliases for manual store operations:

      - `nix-clean`    - run `nh clean` with the configured retention policy
      - `nix-gc`       - run `nix store gc`
      - `nix-optimise` - run `nix store optimise`
      - `nix-repair`   - run `nix store verify --repair`

      ## Dependencies

      ## Dependencies

      - `_.sources.predicates`    - lockFileHas
      - `_.attrsets.*`            - construction, merging, transformation
      - `_.modules.construction`  - mkForce
    '';
    functions = {inherit mkNix mkMaintenance;};
    exports = {
      local = functions;
      alias = {
        inherit (functions) mkNix;
        mkNixMaintenance = mkMaintenance;
      };
    };
  in {inherit doc exports functions;};

  inherit (_.attrsets.access) attrValues;
  inherit (_.attrsets.construction) optionalAttrs;
  inherit (_.attrsets.merging) recursiveUpdate;
  inherit (_.attrsets.transformation) filterAttrs;
  inherit (_.attrsets.predicates) hasAttr;
  inherit (_.modules.construction) mkForce;
  inherit (_.sources.predicates) lockFileHas;
  inherit (_.strings.predicates) hasInfix;

  /**
    Build a NixOS configuration fragment for the Nix daemon and system state.

    Detects required binary caches from the flake lock file and kernel selection,
    merges them with any host-declared overrides, and emits `nix.settings`,
    `system.stateVersion`, and the nix-daemon file descriptor limit.

    # Type
  ```nix
    mkNix :: { host :: AttrSet, pkgs :: AttrSet, tree :: AttrSet } -> AttrSet
  ```

    # Examples
  ```nix
    mkNix { inherit host pkgs tree; }
    # => {
    #   system.stateVersion = "25.11";
    #   nix.settings = {
    #     experimental-features = [ "nix-command" "flakes" "pipe-operators" ];
    #     substituters = [ "https://cache.numtide.com" "https://geo-mirror.chaotic.cx/" ];
    #     trusted-public-keys = [ "cache.numtide.com-1:..." "nyx.chaotic.cx-1:..." ];
    #     ...
    #   };
    #   systemd.services.nix-daemon.serviceConfig.LimitNOFILE = "65536 1048576";
    # }
  ```
  */
  mkNix = {
    host,
    pkgs,
    tree,
    kernel ? (host.packages.kernel or null),
    caches ? (host.caches or {}),
    max-jobs ? (host.specs.cpu.cores or "auto"),
    stateVersion ? host.stateVersion,
    ...
  }: let
    requiresNyx = (kernel != null) && (hasInfix "cachyos" kernel || hasAttr kernel pkgs);
    requiresNumtide = lockFileHas {
      path = tree.store.default;
      field = "owner";
      value = "numtide";
    };

    caches' = let
      common =
        optionalAttrs requiresNumtide {
          numtide = {
            sub = "https://cache.numtide.com";
            key = "cache.numtide.com-1:dGZlQILjUw6nfhbyU3aRjVm4iklknCKEIh5+OR2TXVY=";
          };
        }
        // optionalAttrs requiresNyx {
          nyx = {
            sub = "https://geo-mirror.chaotic.cx/";
            key = "nyx.chaotic.cx-1:CNZOSlPJO5F0utqsPzkZbHkkD7YzNDWHGG6PqS30wMc=";
          };
        };
      custom = caches;
    in
      attrValues (filterAttrs
        (_: c: c.enable or true)
        (recursiveUpdate common custom));
  in {
    system = {inherit stateVersion;};

    nix.settings = {
      inherit max-jobs;
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
      ];
      trusted-users = ["@wheel"];
      substituters = map (c: c.sub) caches';
      trusted-public-keys = map (c: c.key) caches';
    };

    systemd.services.nix-daemon.serviceConfig.LimitNOFILE = mkForce "65536 1048576";
  };

  /**
  Build a NixOS configuration fragment for automated Nix store maintenance.

  Enables `nh clean` on a systemd timer with a retention policy of 3 days or
  5 generations, whichever is greater. Also exposes shell aliases for manual
  store operations when `host.paths.dots` is set.

  # Type
  ```nix
  mkMaintenance :: { host :: AttrSet } -> AttrSet
  ```

  # Examples
  ```nix
  mkMaintenance { host = { paths.dots = "/home/craole/.dots"; }; }
  => {
      programs.nh = {
        enable = true;
        clean = {
          enable = true;
          extraArgs = "--keep-since 3d --keep 5";
        };
        flake = "/home/craole/.dots";
      };
      environment.shellAliases = {
        nix-clean    = "nh clean all --keep-since 3d --keep 5";
        nix-gc       = "nix store gc";
        nix-optimise = "nix store optimise";
        nix-repair   = "nix store verify --repair";
      };
    }
  ```
  */
  mkMaintenance = {dots, ...}: let
    keepArgs = "--keep-since 3d --keep 5";
  in {
    programs.nh = {
      enable = true;
      clean = {
        enable = true;
        extraArgs = keepArgs;
      };
      flake = dots;
    };

    environment.shellAliases = {
      dots-switch = "nh os switch ${dots}";
      dots-boot = "nh os boot ${dots}";
      dots-test = "nh os test ${dots}";
      dots-build = "nh os build ${dots}";
      dots-clean = "nh clean all ${keepArgs}";
      dots-gc = "nix store gc";
      dots-optimise = "nix store optimise";
      dots-repair = "nix store verify --repair";
      dots-dev = "nix develop ${dots}";
      dots-dev-full = "nix develop ${dots}#full";
      dots-dev-minimal = "nix develop ${dots}#minimal";
      dots-dev-media = "nix develop ${dots}#media";
      dots-repl = "nix repl ${dots}#repl";
    };
  };
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
