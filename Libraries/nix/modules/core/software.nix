{
  _,
  names,
  ...
}: let
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
  inherit (_.attrsets.aggregation) recursiveUpdate;
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
    store,
    kernel ? (host.packages.kernel or null),
    caches ? (host.caches or {}),
    max-jobs ? (host.specs.cpu.cores or "auto"),
    stateVersion ? host.stateVersion,
    ...
  }: let
    requiresNyx = (kernel != null) && (hasInfix "cachyos" kernel || hasAttr kernel pkgs);
    requiresNumtide = lockFileHas {
      path = store;
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
  3 generations, whichever is greater. Also exposes shell aliases for manual
  store operations, keyed off `host.paths.src`.

  # Type
  > mkMaintenance :: { src :: String, pkgs :: AttrSet } -> AttrSet

  # Examples
  - mkMaintenance { src = "/home/craole/.dots"; inherit pkgs; }
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
    src,
    pkgs,
    ...
  }: let
    keepArgs = "--keep-since 3d --keep 3";
    fetch = pkgs.writeShellApplication {
      name = "fetch";
      runtimeInputs = with pkgs; [
        fastfetch
        nitch
        onefetch
        tokei
        git
      ];
      text = ''
        mode="normal"
        target="''${1:-.}"

        case "''${1:-}" in
          --full)
            mode="full"
            target="''${2:-.}"
            ;;
        esac

        if [ ! -d "$target" ]; then
          printf 'fetch: directory not found: %s\n' "$target" >&2
          exit 1
        fi

        cd "$target" || exit 1

        onefetch_min() {
          onefetch \
            --no-art \
            --no-title \
            --no-color-palette \
            --disabled-fields \
              project \
              description \
              head \
              version \
              created \
              languages \
              dependencies \
              authors \
              commits \
              lines-of-code \
              churn \
              size \
              contributors \
              url \
              license
        }

        case "$mode" in
          full)
            nitch
            printf '\n'
            if [ -d .git ]; then
              onefetch
              printf '\n'
            fi
            tokei .
            ;;
          *)
            fastfetch
            printf '\n'
            if [ -d .git ]; then
              onefetch_min
            fi
            ;;
        esac
      '';
    };
  in {
    programs.nh = {
      clean = {
        enable = true;
        extraArgs = keepArgs;
      };
      enable = true;
      flake = src;
    };

    environment = {
      systemPackages = [fetch];
      shellAliases = {
        "${names.src}-switch" = "nh os switch ${src}";
        "${names.src}-update" = "nix flake update --flake ${src}";
        "${names.src}-upgrade" = "nix flake update --flake ${src} && nh os switch ${src}";
        "${names.src}-boot" = "nh os boot ${src}";
        "${names.src}-test" = "nh os test ${src}";
        "${names.src}-build" = "nh os build ${src}";
        "${names.src}-clean" = "nh clean all ${keepArgs}";
        "${names.src}-clean-all" = "nh clean all --keep 1";
        "${names.src}-gc" = "nix store gc";
        "${names.src}-gens" = "nh os info";
        "${names.src}-optimise" = "nix store optimise";
        "${names.src}-repair" = "nix store verify --repair";
        "${names.src}-dev" = "nix develop ${src}";
        "${names.src}-dev-ai" = "nix develop ${src}#ai";
        "${names.src}-dev-core" = "nix develop ${src}#core";
        "${names.src}-dev-extras" = "nix develop ${src}#extras";
        "${names.src}-dev-full" = "nix develop ${src}#full";
        "${names.src}-dev-media" = "nix develop ${src}#media";
        "${names.src}-dev-minimal" = "nix develop ${src}#minimal";
        "${names.src}-repl" = "nix repl ${src}#repl";
        "${names.src}-cd" = "cd ${src}";
        "${names.src}-fetch" = "fetch ${src}";
        "${names.src}-fetch-full" = "fetch --full ${src}";
      };
    };
  };
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
