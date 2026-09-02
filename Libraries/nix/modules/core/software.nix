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
    functions = {inherit mkNix mkMaintenance mkFetch;};
    exports = {
      local = functions;
      alias = {
        inherit (functions) mkNix;
        mkNixMaintenance = mkMaintenance;
      };
    };
  in {
    inherit doc exports functions;
  };

  inherit (_.attrsets.access) attrValues;
  inherit (_.attrsets.construction) optionalAttrs;
  inherit (_.attrsets.aggregation) recursiveUpdate;
  inherit (_.attrsets.transformation) filterAttrs;
  inherit (_.attrsets.predicates) hasAttr;
  inherit (_.filesystem.access) readFile;
  inherit (_.modules.construction) mkForce;
  inherit (_.sources.predicates) lockFileHas;
  inherit (_.strings.construction) concat;
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
    flake,
    kernel ? (host.packages.kernel or null),
    caches ? (host.caches or {}),
    max-jobs ? (host.specs.cpu.cores or "auto"),
    stateVersion ? host.stateVersion,
    ...
  }: let
    requiresNyx = (kernel != null) && (hasInfix "cachyos" kernel || hasAttr kernel pkgs);
    requiresNumtide = lockFileHas {
      inherit (flake) path;
      field = "owner";
      value = "numtide";
    };

    caches' = let
      # TODO: Move this to API/global
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
      attrValues (filterAttrs (_: cache: cache.enable or true) (recursiveUpdate common custom));
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
      substituters = map (cache: cache.sub) caches';
      trusted-public-keys = map (cache: cache.key) caches';
    };

    systemd.services.nix-daemon.serviceConfig.LimitNOFILE = mkForce "65536 1048576";
  };

  mkFetch = {
    name,
    pkgs,
    paths,
  }:
    pkgs.writeShellApplication {
      name = "${name}-fetch";
      runtimeInputs = with pkgs; [
        fastfetch
        nitch
        onefetch
        tokei
        git
      ];
      text = readFile (paths.store.lib.sh + "/data/fetch");
    };

  /**
  Build a NixOS configuration fragment for automated Nix store maintenance.

  Enables `nh clean` on a systemd timer with a retention policy of 3 days or
  3 generations, whichever is greater. Also exposes shell aliases for manual
  store operations, keyed off `host.paths.flake`.

  # Type
  > mkMaintenance :: { flake :: String, pkgs :: AttrSet } -> AttrSet

  # Examples
  - mkMaintenance { flake = "/home/craole/.dots"; inherit pkgs; }
  ```nix
  {
      programs.nh = {
        clean = {
          enable = true;
          extraArgs = "--keep-since 3d --keep 3";
        };
        enable = true;
        flake = "/home/craole/.dots";
      };
      environment = { ... };
    }
  ```
  */
  mkMaintenance = {
    flake,
    pkgs,
    keep,
    paths,
    ...
  }: let
    inherit (flake) name home;
    keepArgs = concat " " keep.args;
    fetch = mkFetch {inherit name pkgs paths;};
  in {
    programs = {
      nh = {
        clean = {
          enable = true;
          extraArgs = keepArgs;
        };
        enable = true;
        flake = home;
      };
    };

    environment = {
      systemPackages = [fetch];
      shellAliases = {
        "${name}-switch" = "nh os switch ${home}";
        "${name}-update" = "nix flake update --flake ${home}";
        "${name}-upgrade" = "nix flake update --flake ${home} && nh os switch ${home}";
        "${name}-boot" = "nh os boot ${home}";
        "${name}-test" = "nh os test ${home}";
        "${name}-build" = "nh os build ${home}";
        "${name}-clean" = "nh clean all ${keepArgs}";
        "${name}-clean-all" = "nh clean all --keep 1";
        "${name}-gc" = "nix store gc";
        "${name}-gens" = "nh os info";
        "${name}-optimise" = "nix store optimise";
        "${name}-repair" = "nix store verify --repair";
        "${name}-dev" = "nix develop ${home}";
        "${name}-dev-ai" = "nix develop ${home}#ai";
        "${name}-dev-core" = "nix develop ${home}#core";
        "${name}-dev-extras" = "nix develop ${home}#extras";
        "${name}-dev-full" = "nix develop ${home}#full";
        "${name}-dev-media" = "nix develop ${home}#media";
        "${name}-dev-minimal" = "nix develop ${home}#minimal";
        "${name}-repl" = "nix repl ${home}#repl";
        "${name}-cd" = "cd ${home}";
        "${name}-fetch" = "fetch ${home}";
        "${name}-fetch-full" = "fetch --full ${home}";
      };
    };
  };
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
