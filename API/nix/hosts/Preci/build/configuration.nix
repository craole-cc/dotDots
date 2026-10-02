{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (host.interface) defaultSession isCosmic isGnome isHyprland isNiri isPlasma isX11;
  inherit (host.users) principal;
  inherit (lib.attrsets) attrByPath attrNames attrValues filterAttrs getAttr isAttrs listToAttrs mapAttrs mapAttrsToList optionalAttrs recursiveUpdate removeAttrs;
  inherit (lib.lists) concatMap elem filter flatten foldl' head intersectLists isList optional optionals tail toList unique;
  inherit (lib.modules) mkForce mkIf;
  inherit (lib.strings) concatMapStringsSep concatStringsSep escapeShellArg isString readFile splitString stringLength substring toLower toUpper trim;
  inherit (lib.trivial) div fromHexString;
  inherit (lix) inputs modules overlays;
  inherit (lix.attrsets) mkBin mkBins;
  inherit (lix.fetchers) getFlake fetchModule fetchSource materialize mkGitHubSource;
  inherit (lix.modules) mkNixPkgs;
  inherit (lix.strings) capitalize hashString mkPath mkPathLiteral;
  inherit (lix.trivial) isEmpty isNotEmpty;
  inherit (pkgs) runCommand writeShellApplication writeShellScript writeText;
  inherit (pkgs.stdenv.hostPlatform) isLinux isDarwin;
  inherit (pkgs.stdenvNoCC) mkDerivation;
  flakeInputs = lib.flakes.inputs or null;

  lix = {
    attrsets = {
      mkBin = value: let
        spec =
          if isString value
          then {name = value;}
          else value;
        inherit (spec) name;
        pkg = spec.pkg or name;
        stem = spec.stem or name;
        arguments = spec.arguments or [];
        executable =
          mkPath
          (attrByPath (splitString "." pkg) null pkgs)
          (["bin"] ++ (toList stem));
      in {
        inherit name;
        value = concatStringsSep " " (
          [(escapeShellArg executable)]
          ++ (map escapeShellArg arguments)
        );
      };

      mkBins = list: listToAttrs (map mkBin list);
    };

    fetchers = {
      # Evaluate a fetched tree as a flake. The tree must carry a narHash
      # (which fetchTree provides) so getFlake can run in pure mode with a
      # locked reference -> no warning, no --impure.
      # `builtins.getFlake` is unavailable in older Nix versions, so guard the
      # lookup and fail with a clear message instead of crashing at parse time.
      getFlake = tree:
        if builtins ? getFlake
        then let
          inherit (builtins) getFlake unsafeDiscardStringContext;
          inherit (tree) narHash outPath;
          path = unsafeDiscardStringContext outPath;
        in
          getFlake "path:${path}?narHash=${narHash}"
        else throw "fetchers.getFlake: builtins.getFlake is unavailable in this Nix build";

      # Fetch a source spec into a { outPath, narHash, ... } tree. Accepts
      # either `sha256` (canonical) or `hash` (used by fetchFromGitHub-style
      # specs). Falls back to an unlocked fetch only if neither is set.
      fetchSource = source: let
        narHash = source.sha256 or source.hash or null;
        inherit (source) url;
        type = "tarball";
      in
        if narHash != null
        then fetchTree {inherit narHash type url;}
        else fetchTree {inherit type url;};

      # Materialize a source spec into a resolved record. Downstream
      # consumers rely on:
      #   .tree  -> the fetchTree result, with narHash
      #   .path  -> tree.outPath (string), for imports and NIX_PATH
      #   .value -> the evaluated flake when flake = true, else tree.outPath
      materialize = source: let
        tree = fetchSource source;
        isFlake = source.flake or false;
      in
        source
        // {
          inherit tree;
          path = tree.outPath;
          value =
            if isFlake
            then getFlake tree
            else tree.outPath;
        };

      fetchModule = {
        name,
        path ? null,
        class ? "nixos",
        outputs ? null,
        default ? null,
        enabled ? true,
        inputs ? lib.flakes.inputs or null,
        sources ? lix.inputs,
      }: let
        ctx = "fetchModule";
        # Resolution order for a flake input:
        #   1. Explicit `outputs` attr path, if given (throws if missing).
        #   2. `<namespace>.<name>` — the conventional name-matched export.
        #   3. `<namespace>.default` — the default-export convention.
        #   4. The flake itself — for flakes that ARE a module.
        #
        # Lazy: `namespace` is only forced when `outputs` is null, so callers
        # passing an explicit `outputs` never trip the class validation.
        candidates =
          if outputs != null
          then [outputs]
          else let
            namespace =
              {
                nixos = "nixosModules";
                homeManager = "homeManagerModules";
              }.${
                class
              } or (throw "${ctx}: unsupported class '${class}'");
          in [
            [namespace name]
            [namespace "default"]
            []
          ];

        fromFlake = flake: let
          try = path: attrByPath path null flake;
        in
          if outputs != null
          then let
            value = try outputs;
          in
            if value != null
            then value
            else
              throw "${ctx}: '${name}' does not export ${
                concatStringsSep "." outputs
              }"
          else let
            hits = filter (path: (try path) != null) candidates;
          in
            if isNotEmpty hits
            then try (head hits)
            else null;

        raw = sources.${name} or null;
        # Accept either a resolved source (from `resolve`) or a bare spec.
        # Resolved sources carry `.fromFlake`, which is our marker.
        source =
          if raw == null
          then null
          else if raw ? fromFlake
          then raw
          else materialize raw;

        isFlakeInput = inputs != null && inputs ? ${name};

        flake =
          if source == null || !(source.flake or false)
          then null
          else source.value;

        module =
          if flake != null
          then fromFlake flake
          else null;
      in
        optionalAttrs enabled (
          if isFlakeInput
          then fromFlake inputs.${name}
          else if source != null
          then
            if module != null
            then module
            else if path != null
            then import "${source.path}/${path}"
            else if default != null
            then default source.path
            else throw "${ctx}: no module resolved for '${name}'"
          else throw "${ctx}: '${name}' is neither a flake input nor a pinned source"
        );

      mkGitHubSource = {
        owner,
        repo,
        rev,
        sha256 ? null,
        flake ? false,
        type ? "github",
      }: {
        inherit type owner repo rev sha256 flake;
        url = "https://github.com/${owner}/${repo}/archive/${rev}.tar.gz";
      };
    };

    inputs = let
      /**
      Pinned sources for the non-flake build.

      Each entry is fetched by commit (`rev`) and verified by `sha256`, so the
      result is reproducible. A branch name in `rev` (main, master,
      nixos-unstable) cannot be pinned, because the tarball changes under a fixed
      hash.

      To bump an input:
        1. Set `rev` to the new commit hash.
        2. Set `sha256 = lib.fakeSha256;`
        3. Rebuild. Nix fails with `specified: ... got: sha256:<hash>`.
        4. Paste that `<hash>` into `sha256` and rebuild again.

      `nixpkgs` should match the commit of the active channel, or `<nixpkgs>`
      (used by nixos-rebuild) and `sources.nixpkgs` will disagree.
        Get it with:
          cat /nix/var/nix/profiles/per-user/root/channels/nixos/.git-revision

      `dots` is intentionally unpinned so the local repo can move freely.
      */
      resolve = name: source: let
        fromFlake = flakeInputs != null && flakeInputs ? ${name};
        flakeInput =
          if fromFlake
          then flakeInputs.${name}
          else null;
      in
        if fromFlake
        then
          source
          // {
            inherit fromFlake;
            path = flakeInput.outPath or flakeInput;
            value = flakeInput;
          }
        else (materialize source) // {inherit fromFlake;};
    in
      mapAttrs resolve {
        nixpkgs = mkGitHubSource {
          owner = "NixOS";
          repo = "nixpkgs";
          rev = "20b1ddd1aa5ace70c9468305030aa4f9ef79671b";
          sha256 = "sha256-B44WL6h0XoLjJ41bUPJk0X5SDinLCII//6EcBLXKiJ0=";
        };

        rust = mkGitHubSource {
          owner = "oxalica";
          repo = "rust-overlay";
          rev = "f60c1b57ff805a46b5175c76fc981fb4f81efbcc";
          sha256 = "sha256-r4LDUF+zmJnkftvCVkCrUhSJazsf6EVJF+V2l4/MYbI=";
        };

        home-manager = mkGitHubSource {
          owner = "nix-community";
          repo = "home-manager";
          rev = "4900baf1e219645e4a2acba35723852b2091bc20";
          sha256 = "sha256-BOyZoliWfm/beS4m3FxFKlu5at6npZen1PsWtvzzihk=";
        };

        sops = mkGitHubSource {
          owner = "Mic92";
          repo = "sops-nix";
          rev = "5efb5a6f4f5ab192817d28557dd4d650fa14d866";
          sha256 = "sha256-rs9meAYxW3zzrh43yaW7htrqCD+X9+pupDPHN86fumI=";
          flake = true;
        };

        hermes = mkGitHubSource {
          owner = "NousResearch";
          repo = "hermes-agent";
          rev = "e3dd27ee2d8b011737a4eea8e3eb3d711ab78690";
          sha256 = "sha256-y6NaoG+HCeMPhxRsBXrRFef4hp3FF1svSPNKpI6Xz/E=";
          flake = true;
        };

        ai = mkGitHubSource {
          owner = "numtide";
          repo = "llm-agents.nix";
          rev = "3a78485c5ec8c10ec53915410c724a4492cea4bb";
          sha256 = "sha256-Ho5xXKbluCp1lmvUkVwrN76fUW1NC3RARdNaFMGpEcY=";
          flake = true;
        };

        dotDots = mkGitHubSource {
          owner = "craole-cc";
          repo = "dotDots";
          rev = "main";
        };

        index = mkGitHubSource {
          owner = "nix-community";
          repo = "nix-index-database";
          rev = "9ad722673ab3b3f91f02135e53775825b240b869";
          sha256 = "sha256-Dkg4VKPmDPqTwaiw2WH5br73tXoL1qrOO0xJnR4TlcA=";
        };

        catppuccin = mkGitHubSource {
          owner = "catppuccin";
          repo = "nix";
          rev = "89b3eacf59d6b5eefbc2d69c3a4eb5aaf66d63bc";
          sha256 = "sha256-W5dvgFOuVs24X3G5tUb8C2IHU7ICXNvyGPiWWFjfbuo=";
        };

        catppuccin-konsole = {
          owner = "catppuccin";
          repo = "konsole";
          rev = "3b64040e3f4ae5afb2347e7be8a38bc3cd8c73a8";
          hash = "sha256-d5+ygDrNl2qBxZ5Cn4U7d836+ZHz77m6/yxTIANd9BU=";
        };

        buuf-nestort = {
          url = "https://git.disroot.org/eudaimon/buuf-nestort";
          rev = "ba218523983aec90f1e9facaefeeeeecdcf6d6a5";
          hash = "sha256-6aEM+rL7chkP83Rol6/F5jmG3mo6vALPk2pIvkUK1rU=";
        };
      };

    overlays = {
      rust-overlay = import inputs.rust.path;
    };

    modules = let
      resolveModule = args:
        fetchModule (args
          // {
            inputs = flakeInputs;
            sources = inputs;
          });
    in {
      inherit fetchModule resolveModule;
      mkNixPkgs = {
        host ? {},
        system ?
          host.args.system or (
            throw "mkNixPkgs: 'system' or 'host.args.system' must be provided."
          ),
        extraOverlays ? [],
        config ? ((host.args.config or {}).nixpkgs or {allowUnfree = true;}),
      }:
        import inputs.nixpkgs.path {
          inherit system config;
          overlays =
            optionals
            (isNotEmpty extraOverlays)
            extraOverlays
            ++ optional
            (elem "rust" (host.args.functionalities or []))
            overlays.rust-overlay;
        };
      core = {
        dotDots = inputs.dotDots.path;

        home-manager = resolveModule {
          name = "home-manager";
          path = "nixos";
        };

        catppuccin = resolveModule {
          name = "catppuccin";
          path = "modules/nixos";
        };

        nix-index = resolveModule {
          name = "index";
          path = "nixos-module.nix";
        };

        sops = resolveModule {
          name = "sops";
          outputs = ["nixosModules" "sops"];
        };

        hermes-agent = resolveModule {
          name = "hermes";
          class = "nixos";
        };
      };
      home = {
        hermes-agent = resolveModule {
          name = "hermes";
          class = "homeManager";
        };

        sops = resolveModule {
          name = "sops";
          class = "homeManager";
        };
      };
    };

    strings = {
      inherit (builtins) hashString;
      capitalize = str: toUpper (substring 0 1 str) + substring 1 (-1) str;
      mkPath = root: stems:
        concatStringsSep "/" (
          map toString (
            filter isNotEmpty (
              (toList root) ++ (toList stems)
            )
          )
        );
      mkPathLiteral = root: stems: let
        parts = filter isNotEmpty ((toList root) ++ (toList stems));
      in
        if parts == []
        then ""
        else
          foldl'
          (acc: part: acc + "/${toString part}")
          (head parts)
          (tail parts);
    };

    trivial = {
      isEmpty = value:
        if (value == null)
        then true
        else if isString value
        then ((value == "") || ((stringLength (trim value)) == 0))
        else if isList value
        then value == []
        else if isAttrs value
        then value == {}
        else false;
      isNotEmpty = value: !isEmpty value;
    };
  };

  bins = mkBins [
    "darkman"
    "foot"
    "fd"
    "sd"
    {
      name = "busctl";
      pkg = "systemd";
    }
    {
      name = "dbusSend";
      pkg = "dbus";
      stem = "dbus-send";
    }
    {
      name = "dconGnome";
      pkg = "dconf";
      arguments = ["write" "/org/gnome/desktop/interface"];
    }
    {
      name = "grep";
      pkg = "gnugrep";
    }
    {
      name = "rg";
      pkg = "ripgrep";
    }
    {
      name = "kwriteconfig";
      pkg = "kdePackages.kconfig";
      stem = "kwriteconfig6";
    }
    {
      name = "plasma-apply-colorscheme";
      pkg = "kdePackages.plasma-workspace";
      stem = "plasma-apply-colorscheme";
    }
    {
      name = "pkill";
      pkg = "procps";
    }
    {
      name = "sed";
      pkg = "gnused";
    }
    {
      name = "systemctl";
      pkg = "systemd";
    }
  ];

  host = let
    arch = "x86_64";
    os = "linux";
    admin = "craole";
    repo = "/home/${admin}/Projects/craole-cc/dotDots";

    args = {
      stateVersion = "26.05";
      system = "${arch}-${os}";
      class = "nixos";
      name = "Preci";
      id = "91ba73c7";
      description = "Dell Precision M2800";
      specs = {
        machine = "laptop";
        cpu = {
          inherit arch;
          brand = "intel";
        };
      };
      paths = {
        roots = {
          inherit repo;
          run = "/etc/nixos";
        };
      };
      localization = {
        latitude = 18.015;
        longitude = -77.49;
        city = "Mandeville, Jamaica";
        timeZone = "America/Jamaica";
        defaultLocale = "en_US.UTF-8";
      };
      functionalities = [
        "audio"
        "battery"
        "bluetooth"
        "dualboot-windows"
        "efi"
        "gpu"
        "keyboard"
        "network"
        "nvme"
        "secureboot"
        "storage"
        "touchpad"
        "tpm"
        "video"
        "virtualization"
        "vpn"
        "webcam"
        "wired"
        "wireless"
      ];
      interface = {
        boot = {
          loader = {
            manager = "grub";
            device = "/dev/sda";
            timeout = 1;
          };
        };
        desktops = [
          "plasma"
          "hyprland"
          "niri"
          # "mango"
          # "cosmic"
        ];
      };
      packages = {
        kernel = "linuxPackages_latest";
      };

      principals = [
        {
          name = admin;
          uid = 1000; #? Preserve the established on-disk identity; hash-derived UIDs are the fallback for new principals.
          enable = true;
          autoLogin = true;
          role = "administrator";
          description = "Craig 'Craole' Cole";
          localization = {
            defaultLocale = "en_GB.UTF-8";
          };
          interface = {
            desktops = ["plasma"];
            keyboard = {
              layout = "us";
              variant = "";
            };
            themes = {
              autoSwitch = true;
              polarity = "dark";
              dark = {
                flavor = "frappe";
                accent = "teal";
                icons = "candy-icons";
              };
              light = {
                flavor = "latte";
                accent = "mauve";
                icons = "buuf-nestort";
              };
            };
            cursors = {
              accent = "teal";
              dark = "material";
              light = "material";
            };
            fonts = {
              emoji = ["Noto Color Emoji"];
              monospace = ["Maple Mono NF"];
              sans = ["Monaspace Radon Frozen"];
              serif = ["Noto Serif"];
              material = ["Material Symbols Sharp"];
              clock = ["Rubik"];
            };
          };

          git = {
            settings = {
              alias = {
                project-summary = "!which onefetch && onefetch";
              };
              credential = {
                "https://github.com".helper = "!gh auth git-credential";
                "https://gist.github.com".helper = "!gh auth git-credential";
              };
              init = {
                defaultBranch = "main";
              };
              push = {
                autoSetupRemote = true;
              };
              safe = {
                directory = [repo];
              };
              user = {
                useConfigOnly = true;
              };
              url = {
                "https://github.com/".insteadOf = ["gh:" "github:"];
              };
            };
            profiles = [
              {
                id = "craole-cc";
                name = "craole-cc";
                email = "134658831+craole-cc@users.noreply.github.com";
                root = "craole-cc";
              }
              {
                id = "craole";
                name = "Craole";
                email = "32288735+Craole@users.noreply.github.com";
                root = "Craole";
              }
            ];
          };
          packages = {
            shells = [
              "bash"
              "nushell"
              "powershell"
              "zsh"
            ];
            common = [
              "common"
              "nix"
              "markup"
              "rust"
              "python"
              "shellscript"
              "zig"
            ];
            launchers = ["vicinae"];
          };
          applications = {
            extra = [
              "brave"
              "freetube"
              "ghostty"
              "imv"
              "qbittorrent-enhanced"
              "qimgv"
              "shortwave"
              "vscode-fhs"
            ];
          };
        }
      ];
    };

    paths = let
      stems = {
        repo = {
          root = null;
          stem = [];
        };
        api = {
          root = "repo";
          stem = ["API" "nix"];
        };
        lib = {
          root = "repo";
          stem = ["Libraries"];
        };
        host = {
          root = "hosts";
          stem = args.name;
        };
        build = {
          root = "host";
          stem = "build";
        };
        cfg = {
          root = "repo";
          stem = "Configuration";
        };
        hosts = {
          root = "api";
          stem = "hosts";
        };
        users = {
          root = "api";
          stem = "users";
        };
      };
      mkPaths = base: let
        paths =
          {repo = base;}
          // mapAttrs (
            _: {
              root,
              stem ? [],
            }:
              mkPath paths.${root} stem
          )
          (removeAttrs stems ["repo"]);
      in
        paths;

      local = mkPaths (args.paths.roots.repo or (throw ''
        'args.paths.roots.repo is required to build local paths; set it to the local dotDots repository checkout.'
      ''));
      store = mkPaths (inputs.dotDots.path or (throw ''
        'inputs.dotDots.path is required to build store paths.'
      ''));
      default = local;
    in
      default
      // {
        inherit local store;
        roots = args.paths.roots;
        run = args.paths.roots.run;
      };

    localization = recursiveUpdate {
      latitude = 18.015;
      longitude = -77.49;
      city = "Mandeville, Jamaica";
      timeZone = "America/Jamaica";
      defaultLocale = "en_US.UTF-8";
    } (args.localization or {});

    users = let
      #? Explicit UIDs are stable pins; missing UIDs are deterministically
      #? derived from role + name, matching the developed user schema.
      uidRanges = {
        administrator = {
          min = 1000;
          max = 59999;
        };
        normal = {
          min = 1000;
          max = 59999;
        };
        user = {
          min = 1000;
          max = 59999;
        };
        guest = {
          min = 1000;
          max = 59999;
        };
        service = {
          min = 400;
          max = 999;
        };
      };

      seedUid = {
        role,
        name,
        range,
      }: let
        hash = hashString "sha256" "${role}:${name}";
        seed = fromHexString (substring 0 8 hash);
        span = range.max - range.min + 1;
        remainder = seed - span * (div seed span);
      in
        range.min + remainder;

      resolveUid = {
        role,
        name,
        uid ? null,
      }: let
        range = uidRanges.${role} or uidRanges.user;
      in
        if uid != null
        then uid
        else seedUid {inherit role name range;};

      normalize = user: let
        role = user.role or "normal";
        isNormalUser = role != "service";
        uid = resolveUid {
          inherit role;
          inherit (user) name;
          uid = user.uid or null;
        };

        requestedPaths = user.paths or {};
        requestedRoots = requestedPaths.roots or {};
        home = requestedRoots.home or "/home/${user.name}";

        userLocalization =
          recursiveUpdate
          localization
          (
            (user.localization or {})
            // optionalAttrs (user ? defaultLocale) {
              inherit (user) defaultLocale;
            }
          );

        userInterface = user.interface or {};
        keyboard =
          recursiveUpdate
          {
            layout = "us";
            variant = "";
          }
          (userInterface.keyboard or (user.keyboard or {}));
        desktops = userInterface.desktops or [];
        desktop =
          if isNotEmpty desktops
          then head desktops
          else user.desktop or "plasma";
        themes = userInterface.themes or (user.theme or {});
        cursors = userInterface.cursors or (user.cursors or {});
        fonts = userInterface.fonts or (user.fonts or {});
        icons = {
          dark = themes.dark.icons or user.icons.dark or "Papirus-Dark";
          light = themes.light.icons or user.icons.light or "Papirus-Light";
        };

        userPackages = user.packages or {};
        shells = userPackages.shells or userPackages.shell or user.shells or ["bash"];
        coding = userPackages.common or user.coding or [];
        launchers = userPackages.launchers or userPackages.launcher or user.launchers or [];
        applications = user.applications or {};
        apps =
          (applications.extra or [])
          ++ (applications.allowed or [])
          ++ (user.apps or []);
      in
        user
        // {
          inherit
            role
            uid
            shells
            coding
            launchers
            apps
            isNormalUser
            keyboard
            desktop
            themes
            cursors
            fonts
            icons
            applications
            ;
          isSystemUser = !isNormalUser;
          paths =
            recursiveUpdate
            {
              roots.home = home;
              cfg = {
                source = paths.local.cfg;
                target = "${home}/.config";
              };
            }
            requestedPaths;
          linger = isNormalUser;
          localization = userLocalization;
          inherit (userLocalization) defaultLocale;
          theme = themes;
          interface =
            recursiveUpdate
            userInterface
            {inherit keyboard desktops themes cursors fonts;};
          packages =
            recursiveUpdate
            userPackages
            {
              inherit shells launchers;
              common = coding;
            };
        };

      normalized =
        mapAttrs
        (_: normalize) (
          listToAttrs (
            map (value: {
              inherit value;
              inherit (value) name;
            })
            (args.principals or [])
          )
        );

      enabled =
        filterAttrs
        (_: user: user.enable or false == true)
        normalized;

      disabled =
        filterAttrs
        (_: user: user.enable or false == false)
        normalized;
      normal =
        filterAttrs
        (_: user: user.isNormalUser)
        normalized;

      principal = enabled.${head (attrNames enabled)};

      core =
        mapAttrs
        (
          _: user:
            {
              description = user.description or user.name;
              inherit (user) isNormalUser isSystemUser name linger uid;
              home = user.paths.roots.home;
              extraGroups =
                optionals
                (user.role == "administrator") ["networkmanager" "wheel"];
              shell = getAttr (head user.shells) pkgs;
            }
            // optionalAttrs (user ? hashedPassword) {inherit (user) hashedPassword;}
            // optionalAttrs (user ? hashedPasswordFile) {inherit (user) hashedPasswordFile;}
            // optionalAttrs (user ? password) {inherit (user) password;}
        )
        normalized;

      autoLogin = let
        candidates =
          filterAttrs
          (_: user: user.autoLogin or false)
          normalized;
        enable = isNotEmpty candidates;
      in {
        inherit enable;
        user =
          if enable
          then head (attrNames candidates)
          else principal.name;
      };
    in {inherit enabled disabled normal principal core autoLogin;};

    interface = let
      requestedDesktops = unique (
        (args.interface.desktops or [])
        ++ concatMap (user: user.interface.desktops or []) (attrValues users.normal)
      );
      normalized = map toLower requestedDesktops;

      aliases = {
        plasma = ["plasma" "plasma6" "kde"];
        hyprland = ["hyprland" "hypr" "hype"];
        niri = ["niri"];
        gnome = ["gnome"];
        cosmic = ["cosmic"];
        i3 = ["i3"];
        bspwm = ["bspwm"];
        openbox = ["openbox"];
        lab = ["labwc" "lab"];
        mango = ["mango" "mangowc"];
      };

      protocols = let
        collect = list: intersectLists normalized list;
      in {
        wayland = collect [
          "cosmic"
          "gnome"
          "hyprland"
          "mango"
          "niri"
          "plasma"
        ];

        x11 = collect [
          "bspwm"
          "i3"
          "labwc"
          "openbox"
        ];
      };

      isRequired = desktop:
        isNotEmpty
        (intersectLists aliases.${desktop} normalized);
    in
      recursiveUpdate (args.interface or {}) {
        inherit protocols;

        boot.loader =
          recursiveUpdate {
            manager = "systemd-boot";
            device = "nodev";
            timeout = 1;
          }
          (args.interface.boot.loader or {});

        isBspwm = isRequired "bspwm";
        isCosmic = isRequired "cosmic";
        isGnome = isRequired "gnome";
        isHyprland = isRequired "hyprland";
        isI3 = isRequired "i3";
        isLab = isRequired "lab";
        isMango = isRequired "mango";
        isNiri = isRequired "niri";
        isOpenbox = isRequired "openbox";
        isPlasma = isRequired "plasma";
        isWayland = isNotEmpty protocols.wayland;
        isX11 = isNotEmpty protocols.x11;
        defaultSession = users.principal.desktop or "plasma";
      };

    aesthetics = let
      of = user: let
        theme =
          recursiveUpdate
          {
            autoSwitch = true;
            polarity = "dark";
            dark = {
              flavor = "frappe";
              accent = "blue";
            };
            light = {
              flavor = "latte";
              accent = "blue";
            };
          }
          (
            recursiveUpdate
            (interface.theme or {})
            (user.theme or {})
          );

        icons =
          recursiveUpdate
          {
            dark = "Papirus-Dark";
            light = "Papirus-Light";
          }
          (
            recursiveUpdate
            (interface.icons or {})
            (user.icons or {})
          );

        kdeScheme = let
          mkName = mode: let
            inherit (theme.${mode}) flavor accent;
          in
            "Catppuccin"
            + capitalize flavor
            + capitalize accent;
        in {
          dark = mkName "dark";
          light = mkName "light";
        };
      in {
        inherit theme icons kdeScheme;
        #? The palette for the mode set in `polarity`, used for static things like boot and console
        active = theme.${theme.polarity};
      };
    in
      with users; {
        inherit of;
        primary = of principal;
        users = mapAttrs (_: of) normal;
      };

    variables = let
      inherit (args) name;
      inherit (paths) local store;
      inherit (users) principal;
      env = variables;
      HOST = name;
    in {
      #~@ Paths
      DOTS = local.repo;
      DOTS_STORE = store.repo;
      DOTS_LOCAL = local.repo;
      DOTS_BUILD = paths.run;
      DOTS_HOSTS = env.DOTS_LOCAL_HOSTS;
      DOTS_LOCAL_HOSTS = local.hosts;
      DOTS_STORE_HOSTS = store.hosts;
      "DOTS_LOCAL_HOST_${HOST}" = local.host;
      "DOTS_STORE_HOST_${HOST}" = store.host;
      DOTS_STORE_CFG = store.cfg;
      DOTS_LOCAL_CFG = local.cfg;

      #~@ Editor
      EDITOR = "hx";
      VISUAL = "code";

      #~@ Inputs
      # REV_URL_CORE = sources.revision.nixpkgs.url;
      # REV_URL_HOME = sources.revision.home-manager.url;
      # REV_URL_INDEX = sources.revision.nix-index.url;
      # REV_URL_CATPPUCCIN = sources.revision.catppuccin.url;
      # REV_URL_DOTS = sources.revision.dots.url;

      #~@ Metadata
      inherit HOST;

      #~@ Theme
      THEME_KDE_LIGHT = (aesthetics.of principal).kdeScheme.light;
      THEME_KDE_DARK = (aesthetics.of principal).kdeScheme.dark;
      THEME_GTK_LIGHT = "catppuccin-latte-blue-standard";
      THEME_GTK_DARK = "catppuccin-frappe-blue-standard";
      THEME_ICONS_LIGHT = (aesthetics.of principal).icons.light;
      THEME_ICONS_DARK = (aesthetics.of principal).icons.dark;
    };

    packages = let
      inherit (inputs.ai.value.packages.${args.system}) codex chatgpt;

      #? Per-shell packages are included in the native system fallback and may
      #? also be selected into a user's Home Manager profile.
      forShells = {
        bash = with pkgs; [bash];
        fish = with pkgs; [fish];
        nushell = with pkgs;
          [
            nushell
            nu-lint
            nufmt
          ]
          ++ (with pkgs.nushellPlugins; [
            polars
            gstat
            skim
            query
            formats
            desktop_notifications
          ]);
        powershell = with pkgs; [
          powershell
          powershell-editor-services

          (let
            name = "pwshfmt";
            formatter = let
              script = mkPath paths.store.lib [
                "powershell"
                "Admin"
                "pwshfmt.ps1"
              ];
              exec = ''
                exec pwsh -NoProfile -NonInteractive -File ${script} "$@"
              '';
            in {inherit script exec;};

            PSModulePath = let
              pname = "PSScriptAnalyzer";
              version = "1.25.0";
              pkg = mkDerivation {
                inherit pname version;
                src = fetchurl {
                  url = "https://www.powershellgallery.com/api/v2/package/${pname}/${version}";
                  hash = "sha256-FOY0yCjrmO+59AspGLqQ8TntXszfZjoqdHc22ZaZXWA="; #? lib.fakeHash to update
                };
                nativeBuildInputs = [unzip];
                dontUnpack = true;
                dontBuild = true;
                installPhase = ''
                  mkdir -p "$out/share/powershell/Modules/${pname}"
                  unzip -q "$src" -d "$out/share/powershell/Modules/${pname}"
                '';
              };
              export = ''
                export PSModulePath="${pkg}/share/powershell/Modules''${PSModulePath:+:$PSModulePath}"
              '';
            in {inherit pname version pkg export;};
          in
            writeShellApplication {
              inherit name;
              runtimeInputs = [powershell];
              text = ''
                ${PSModulePath.export}
                ${formatter.exec}
              '';
            })
        ];
        zsh = with pkgs; [zsh zi];
      };

      #? Per-language/tooling packages are available in the native system
      #? fallback; Home Manager may additionally select them per user.
      forCoding = {
        common = with pkgs; [
          age
          bat
          btop
          coreutils
          curl
          dbus
          delta
          diffutils
          dua
          dust
          diff-so-fancy
          efibootmgr
          eza
          fastfetch
          fd
          fend
          figlet
          file
          findutils
          fzf
          gawk
          getent
          gh
          gitui
          glib
          gnused
          gum
          helix
          imagemagick
          imv
          jq
          jql
          lolcat
          lsd
          lshw
          onefetch
          ouch
          p7zip
          patch
          pciutils
          pkg-config
          procps
          procs
          pstree
          ripgrep
          rsync
          sd
          sad
          sops
          speedtest-go
          systemd
          tmux
          nodejs_22
          trashy
          treefmt
          udiskie
          usbutils
          uutils-coreutils-noprefix
          wakeonlan
          viu
          wget
          wlr-randr
          yazi
        ];

        markup = with pkgs;
          [
            actionlint
            biome
            rumdl
            stylua
            tombi
            typos
            typst
            typstyle
          ]
          ++ (with typstPackages; [typsy])
          ++ [
            (writeShellApplication {
              name = "yamlfmt";
              runtimeInputs = with pkgs; [yamlfmt gnugrep];
              text = ''
                content="$(cat)"

                # sops-encrypted files carry a top-level `sops:` metadata block
                # and/or AES256-GCM ciphertext. Never reformat them -> the MAC
                # and the `env: |` block scalar are structural, not cosmetic.
                if printf '%s' "$content" | grep -qE '^sops:|ENC\[AES256_GCM'; then
                  printf '%s' "$content"
                  exit 0
                fi

                printf '%s' "$content" | yamlfmt -
              '';
            })
          ];

        nix = with pkgs; [
          alejandra
          cachix
          lorri
          manix
          nil
          nix-diff
          nix-index
          nix-info
          nix-output-monitor
          nix-prefetch
          nix-prefetch-docker
          nix-prefetch-github
          nix-prefetch-scripts
          nixd
          nixfmt
          nvfetcher
          statix
        ];

        python = with pkgs; [
          python3Minimal
          ruff
        ];

        rust = with pkgs; [
          cargo
          clippy
          rust-analyzer
          rustc
          rustfmt
          leptosfmt
          gcc
        ];

        shellscript = with pkgs; [
          shellcheck
          shfmt

          (writeShellApplication {
            name = "shflint";
            runtimeInputs = [shellcheck shfmt];
            text = ''
              ${readFile (
                mkPath paths.store.lib [
                  "posix"
                  "project"
                  "formatters"
                  "shflint"
                ]
              )}
            '';
          })
        ];

        zig = with pkgs; [
          zig
          ziglint
          zls
        ];
      };

      catppuccinKonsole = let
        pname = "catppuccin-konsole";
        flavors = unique (
          concatMap
          (user: with user.theme; [dark.flavor light.flavor])
          (attrValues aesthetics.users)
        );
      in
        mkDerivation {
          inherit pname;
          version = "3b64040";
          src = pkgs.fetchFromGitHub {inherit (inputs.${pname}) owner repo rev hash;};
          dontBuild = true;
          dontFixup = true;
          installPhase = ''
            mkdir -p $out/share/konsole
            ${
              concatMapStringsSep "\n" (flavor: ''
                cp "$(find . -iname '*${flavor}*.colorscheme' | head -n1)" \
                  $out/share/konsole/Catppuccin-${capitalize flavor}.colorscheme
              '')
              flavors
            }
          '';
        };

      forInterface =
        (with pkgs; [adwaita-icon-theme darkman])
        ++ optionals (with interface; isX11 || isWayland) (with pkgs; [
          mpvc
          mpv
          imagemagick
          imv
        ])
        ++ optionals interface.isWayland (with pkgs; [
          wl-clipboard
          xwayland-satellite
          foot
        ])
        ++ optional interface.isNiri (with pkgs; [alacritty])
        ++ optional interface.isHyprland (with pkgs; [kitty])
        ++ optionals interface.isPlasma (with pkgs.kdePackages; [
          kate
          kconfig
          koi
          plasma-workspace
          catppuccinKonsole
          yakuake
        ])
        ++ map
        (name: let
          icons = {
            buuf-nestort = let
              pname = "buuf-nestort";
            in
              mkDerivation {
                inherit pname;
                version = "2026-07-29";
                src = pkgs.fetchgit {inherit (inputs.${pname}) url rev hash;};
                dontBuild = true;
                dontFixup = true;
                installPhase = ''
                  mkdir -p $out/share/icons/${pname}
                  cp -r . $out/share/icons/${pname}
                  chmod -R u+w $out/share/icons/${pname}
                  sed -i 's/^Inherits=.*/Inherits=oxygen,breeze,Adwaita,hicolor/' \
                    $out/share/icons/${pname}/index.theme
                '';
              };

            "catppuccin-konsole" = let
              pname = "catppuccin-konsole";
              flavors = unique (
                concatMap
                (user: with user.theme; [dark.flavor light.flavor])
                (attrValues aesthetics.users)
              );
            in
              mkDerivation {
                inherit pname;
                version = "3b64040";
                src = pkgs.fetchFromGitHub {inherit (inputs.${pname}) owner repo rev hash;};
                dontBuild = true;
                dontFixup = true;
                installPhase = ''
                  mkdir -p $out/share/konsole
                  ${
                    concatMapStringsSep "\n" (flavor: ''
                      cp "$(find . -iname '*${flavor}*.colorscheme' | head -n1)" \
                        $out/share/konsole/Catppuccin-${capitalize flavor}.colorscheme
                    '')
                    flavors
                  }
                '';
              };
          };
        in
          icons.${name} or pkgs.${name})
        (unique (
          concatMap
          (elements: with elements.icons; [dark light])
          (attrValues aesthetics.users)
        ))
        ++ [
          #~@ Theme Management
          (let
            perUser = attrValues aesthetics.users;
          in
            pkgs.catppuccin-kde.override {
              flavour = unique (
                concatMap
                (user: with user.theme; [dark.flavor light.flavor])
                perUser
              );
              accents = unique (
                concatMap
                (user: with user.theme; [dark.accent light.accent])
                perUser
              );
            })

          #~@ Darkman
          (let
            mkUserModeScript = user: mode: let
              MODE = toUpper mode;
              inherit (aesthetics.users.${user.name}) icons kdeScheme;
              theme = {
                kde = kdeScheme.${mode};
                gtk = variables."THEME_GTK_${MODE}";
              };
              icon = icons.${mode};
              konsole = {
                name = "Catppuccin-${capitalize mode}";
                file = "Catppuccin-${capitalize mode}.profile";
              };
              foot = {
                signal =
                  if mode == "dark"
                  then "USR1"
                  else "USR2";
              };
              vscode = {
                theme =
                  if mode == "dark"
                  then "Catppuccin Frappé"
                  else "Catppuccin Latte";
                configDirs = [
                  ".config/Code/User"
                  ".config/Code - Insiders/User"
                  ".config/VSCodium/User"
                ];
              };
            in ''
              ${bins.pkill} -${foot.signal} -x foot || true
              ${bins.kwriteconfig} --file konsolerc  --group "Desktop Entry" --key DefaultProfile "${konsole.file}"
              ${bins.kwriteconfig} --file yakuakerc  --group "Desktop Entry" --key DefaultProfile "${konsole.file}"
              ${bins.kwriteconfig} --notify --file kdeglobals --group Icons --key Theme ${icon}

              for terminal in $(${bins.busctl} --user call org.kde.yakuake /yakuake/sessions org.kde.yakuake terminalIdList 2>/dev/null | ${bins.sed} 's/^s "//; s/"$//; s/,/ /g'); do
                ${bins.busctl} --user call org.kde.yakuake /Sessions/$((terminal + 1)) org.kde.konsole.Session setProfile s "${konsole.name}" >/dev/null 2>&1 || true
              done

              if ${bins.systemctl} --user is-active --quiet plasma-plasmashell.service; then
                ${bins.plasma-apply-colorscheme} ${theme.kde}
              fi

              ${bins.kwriteconfig} --notify --file kdeglobals --group Icons --key Theme ${icon}
              for group in 0 1 2 3 4 5; do
                ${bins.dbusSend} --session --type=signal /KIconLoader org.kde.KIconLoader.iconChanged int32:$group
              done
              ${bins.dconGnome}/color-scheme "'prefer-${mode}'"
              ${bins.dconGnome}/gtk-theme "'${theme.gtk}'"
              ${bins.dconGnome}/icon-theme "'${icon}'"

              ${concatMapStringsSep "\n" (dir: ''
                  vscodeSettings="$HOME/${dir}/settings.json"
                  if [ -f "$vscodeSettings" ]; then
                    if ${bins.rg} -q '"workbench.colorTheme"' "$vscodeSettings"; then
                      ${bins.sed} -i -E 's|("workbench.colorTheme"[[:space:]]*:[[:space:]]*)"[^"]*"|\1"${vscode.theme}"|' "$vscodeSettings"
                    else
                      ${bins.sed} -i '0,/{/s|{|{\n  "workbench.colorTheme": "${vscode.theme}",|' "$vscodeSettings"
                    fi
                    ${bins.sed} -i -E 's|("window.autoDetectColorScheme"[[:space:]]*:[[:space:]]*)true|\1false|' "$vscodeSettings"
                  fi
                '')
                vscode.configDirs}
              ${bins.systemctl} --user try-restart plasma-plasmashell.service
            '';

            themeHook = let
              name = "darkman-theme-hook";
            in "${writeShellApplication {
              inherit name;
              text = ''
                user="$(whoami)"
                mode="''${1:-}"
                case "$user:$mode" in
                ${
                  let
                    userModes =
                      concatMap
                      (user: map (mode: {inherit user mode;}) ["dark" "light"])
                      (attrValues users.normal);

                    mkArm = {
                      user,
                      mode,
                    }: ''
                      ${user.name}:${mode}) ${mkUserModeScript user mode} ;;
                    '';
                  in
                    concatStringsSep "\n" (map mkArm userModes)
                }
                *) exit 0 ;;
                esac
              '';
            }}/bin/${name}";
          in
            runCommand "darkman-theme-hook-install" {} ''
              mkdir -p $out/share/darkman
              ln -s ${themeHook} $out/share/darkman/theme
            '')

          (writeShellApplication {
            name = "theme-toggle";
            runtimeInputs = with pkgs; [coreutils libnotify];
            text = let
              #? Used unless DMS/Matugen is currently running.
              fallback = {
                inherit (variables) THEME_KDE_LIGHT;
                inherit (variables) THEME_KDE_DARK;
                inherit (variables) THEME_GTK_LIGHT;
                inherit (variables) THEME_GTK_DARK;
              };
              #? Overrides fallback's keys while DMS is active.
              dms = {
                THEME_KDE_LIGHT = "DankMatugenLight";
                THEME_KDE_DARK = "DankMatugenDark";
                THEME_GTK_LIGHT = "DankMatugenLight";
                THEME_GTK_DARK = "DankMatugenDark";
              };
              #? Always assigned, regardless of DMS.
              static = {
                inherit (variables) THEME_ICONS_LIGHT;
                inherit (variables) THEME_ICONS_DARK;
              };
              mkAssigns = vals:
                concatStringsSep "\n" (
                  mapAttrsToList
                  (key: value: "${key}=${escapeShellArg value};")
                  vals
                );
              exported =
                (attrNames fallback)
                ++ (attrNames static)
                ++ ["THEME_KDE_SCHEME_LIGHT" "THEME_KDE_SCHEME_DARK"];
            in ''
              #> Use the DMS-generated Matugen schemes only while DMS is running.
              if
                command -v dms >/dev/null 2>&1 &&
                  dms ipc call theme getMode >/dev/null 2>&1
              then
                ${mkAssigns dms}
              else
                ${mkAssigns fallback}
              fi

              ${mkAssigns static}
              THEME_KDE_SCHEME_LIGHT="$THEME_KDE_LIGHT";
              THEME_KDE_SCHEME_DARK="$THEME_KDE_DARK";

              export ${concatStringsSep " " exported}

              ${readFile (mkPath paths.store.lib [
                "posix"
                "interface"
                "theme"
                "theme-switch.sh"
              ])}
            '';
          })
        ];

      forSystem = flatten (
        with pkgs;
          [
            bitwarden-cli
            bitwarden-desktop
            codex
            chatgpt
            coreutils
            curl
            diffutils
            file
            findutils
            gawk
            git
            gnused
            lshw
            patch
            pciutils
            procps
            rsync
            sd
            usbutils
            wget
          ]
          ++ optionals isLinux (with pkgs; [bubblewrap xsel])
          ++ optionals isDarwin (with pkgs; [pngpaste])
          ++ [
            (writeShellApplication {
              name = "nixos-switch";
              runtimeInputs = with pkgs; [coreutils git gum nixos-rebuild];
              text = ''
                ${
                  concatStringsSep "\n" (mapAttrsToList
                    (key: value: "export ${key}=${escapeShellArg value}")
                    (filterAttrs (_: isString) variables))
                }
                ${
                  readFile (mkPath paths.store.lib [
                    "posix"
                    "packages"
                    "manager"
                    "nix"
                    "nixos-switch.sh"
                  ])
                }
              '';
            })
            (writeShellApplication {
              name = "sups";
              runtimeInputs = with pkgs; [sups gum];
              text = ''
                ${readFile (
                  mkPath paths.store.lib [
                    "posix"
                    "environment"
                    "sups"
                  ]
                )}
              '';
            })
          ]
      );
    in {
      inherit forShells forCoding forInterface forSystem;
      complete = flatten (
        [forInterface forSystem]
        ++ (attrValues forShells)
        ++ (attrValues forCoding)
      );
    };
  in {
    inherit
      args
      paths
      localization
      users
      interface
      aesthetics
      variables
      packages
      ;
  };
in {
  imports =
    [./hardware-configuration.nix]
    ++ (with modules.core; [
      home-manager
      nix-index
      catppuccin
      sops

      #? Inert. Imported for its options and assertions only; `enable`
      #? defaults to false, so no unit, user or group is created and the
      #? gateway keeps running from the Home Manager module below. Importing
      #? both without disabling one of them would put two `hermes-backend`
      #? units on the same port (9119) with separate state directories.
      hermes-agent
    ]);

  boot = {
    loader = with host.interface.boot.loader; {
      grub = let
        resolution = "1920x1080";
      in {
        inherit device;
        enable = manager == "grub";
        useOSProber = true;
        fsIdentifier = "provided";
        gfxmodeBios = resolution;
        gfxmodeEfi = resolution; #? This host is Bios, but this is a no-op
      };
      systemd-boot = {
        enable = manager == "systemd-boot";
        consoleMode = "max";
      };
      inherit timeout;
    };

    kernelPackages =
      pkgs.${host.args.packages.kernel or "linuxPackages_latest"};
  };

  catppuccin = {
    enable = true;
    autoEnable = true;
    inherit (host.aesthetics.primary.active) flavor accent;
  };

  console = {
    keyMap = host.users.principal.keyboard.layout;
  };

  documentation = {
    nixos.enable = false;
  };

  environment = {
    pathsToLink = mkIf host.interface.isPlasma ["/share/konsole"];
    plasma6.excludePackages = with pkgs.kdePackages; [
      elisa
      gwenview
      kate
      khelpcenter
      kinfocenter
    ];
    sessionVariables = host.variables;
    systemPackages = host.packages.complete;
  };

  fonts = let
    clock = {
      name = "Rubik";
      package = pkgs.rubik;
    };
    emoji = {
      name = "Noto Color Emoji";
      package = pkgs.noto-fonts-color-emoji;
    };
    material = {
      name = "Material Symbols Sharp";
      package = pkgs.material-symbols;
    };
    monospace = {
      name = "Maple Mono NF";
      package = pkgs.maple-mono.NF-unhinted;
    };
    sansSerif = {
      name = "Monaspace Radon Frozen";
      package = pkgs.monaspace;
    };
    serif = {
      name = "Noto Serif";
      package = pkgs.noto-fonts;
    };
  in {
    packages =
      [
        clock.package
        emoji.package
        material.package
        monospace.package
        sansSerif.package
        serif.package
      ]
      ++ (with pkgs.nerd-fonts; [
        jetbrains-mono
        zed-mono
      ]);
    fontconfig = {
      defaultFonts = {
        monospace = [monospace.name];
        sansSerif = [sansSerif.name];
        serif = [serif.name];
        emoji = [emoji.name];
      };
    };
  };

  i18n = {
    inherit (host.users.principal) defaultLocale;
  };

  networking = {
    hostName = host.args.name;
    hostId = host.args.id;
    networkmanager.enable = true;
  };

  nix = {
    settings = {
      access-tokens = [
        "github.com=$(gh auth token)"
      ];

      experimental-features = [
        "nix-command"
        "flakes"
      ];

      extra-substituters = [
        "https://cache.numtide.com"
      ];

      extra-trusted-public-keys = [
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      ];
    };

    nixPath = [
      "nixos-config=${host.variables.DOTS_BUILD}/configuration.nix"
      "nixpkgs=${inputs.nixpkgs.path}"
    ];
  };

  nixpkgs = {
    pkgs = mkNixPkgs {inherit host;};
  };

  programs = {
    atuin = {
      enable = true;
      settings = {
        auto_sync = false;
        update_check = false;
        style = "compact";
      };
    };
    bash = {
      enable = true;
      blesh.enable = true;
      undistractMe.enable = true;
    };

    bat = {
      enable = true;

      extraPackages = with pkgs.bat-extras; [
        batdiff
        batman
        prettybat
      ];

      settings = {};
    };

    dconf = {
      enable = true;
    };
    direnv = {
      enable = true;
      silent = true;
      angrr = {
        enable = true;
      };
    };

    foot = {
      enable = true;
      xdg.serverAutostart = false;
      settings = {
        main = {
          dpi-aware = "yes";
          font = "monospace:size=18";
          term = "xterm-256color";
          include = let
            dirs = {
              config = with host.paths; {
                local = mkPath local.cfg "foot";
                store = mkPath store.cfg "foot";
              };

              themes = {
                pkgs = mkPath pkgs.foot.themes ["share" "foot" "themes"];
                dots = mkPath dirs.config.store "themes";
              };
            };

            mkThemePath = {
              from ? "pkgs",
              name,
            }:
              mkPath dirs.themes.${from} [name];
          in [
            (mkThemePath {name = "catppuccin-frappe";})
            (mkThemePath {name = "catppuccin-latte";})
            (mkThemePath {
              name = "dark.ini";
              from = "dots";
            })
            (mkThemePath {
              name = "light.ini";
              from = "dots";
            })
            (mkPath dirs.config.store "config.ini")
          ];
        };
        mouse = {
          hide-when-typing = "yes";
        };
      };
    };

    git = let
      user = host.users.principal;
      git = user.git or {};
      profiles = git.profiles or [];
      profileIncludes = listToAttrs (
        map
        (profile: {
          name = "gitdir:${user.paths.roots.home}/Projects/${profile.root}/";
          value = {
            path = writeText "git-profile-${profile.id}.gitconfig" ''
              [user]
                name = ${profile.name}
                email = ${profile.email}
            '';
          };
        })
        profiles
      );
    in {
      enable = true;
      lfs = {
        enable = true;
        enablePureSSHTransfer = true;
      };
      prompt.enable = true;
      config =
        (git.settings or {})
        // optionalAttrs (isNotEmpty profileIncludes) {
          includeIf = profileIncludes;
        };
    };

    hyprland = {
      enable = host.interface.isHyprland;
      withUWSM = true;
    };

    hyprlock = {
      enable = host.interface.isHyprland;
    };

    iio-hyprland = {
      enable = host.interface.isHyprland;
    };

    kbdlight = {
      enable = true;
    };

    kdeconnect = {
      enable = true;
    };

    labwc = {
      enable = host.interface.isLab;
    };

    lazygit = {
      inherit (config.programs.git) enable;
    };

    less = {
      enable = true;
      envVariables = {
        LESS = "--quit-if-one-screen";
      };
    };

    mango = {
      enable = host.interface.isMango;
    };

    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      withNodeJs = true;
      withPython3 = true;
    };

    nh = {
      enable = true;
      clean = {
        enable = true;
        extraArgs = "--keep-since 7d --keep 3";
      };
      flake = host.paths.local.repo;
    };

    niri = {
      enable = host.interface.isNiri;
    };

    nix-index = {
      enable = true;
    };

    nix-index-database = {
      enable = true;
      comma.enable = true;
    };

    nix-ld = {
      enable = true;
    };

    starship = {
      enable = true;
      transientPrompt.enable = true;
      settings = fromTOML (readFile (
        mkPath host.paths.local.cfg ["starship" "config.toml"]
      ));
    };

    tmux = {
      enable = true;
      clock24 = true;
      historyLimit = 5000;
      keyMode = "vi";
      newSession = true;
      plugins = with pkgs.tmuxPlugins; [
        catppuccin
        tmux-sessionx
        tmux-thumbs
        tmux-window-name
        tmux-which-key
      ];
      resizeAmount = 6;
      reverseSplit = false;
      shortcut = "b";
      terminal = "screen-256color";
    };
  };

  security = {
    sudo = {
      extraConfig = ''
        Defaults env_keep += "EDITOR VISUAL"
      '';
      extraRules = [
        {
          users = [host.users.principal.name];
          commands = [
            {
              command = "ALL";
              options = ["NOPASSWD"];
            }
          ];
        }
      ];
    };

    rtkit.enable = true;
  };

  services = {
    displayManager = {
      enable = true;
      defaultSession = mkForce (
        if isPlasma
        then "plasma"
        else if isNiri
        then "niri"
        else defaultSession
      );

      autoLogin = {
        inherit (host.users.autoLogin) enable user;
      };

      plasma-login-manager = {
        enable = isPlasma;
      };
    };

    desktopManager = {
      plasma6 = {
        enable = isPlasma;
      };

      gnome = {
        enable = isGnome;
      };

      cosmic = {
        enable = isCosmic;
      };
    };

    logind = {
      settings.Login = {
        HandleLidSwitch = "ignore";
        HandleLidSwitchExternalPower = "ignore";
        HandleLidSwitchDocked = "ignore";
        HandleSuspendKey = "ignore";
        HandleHibernateKey = "ignore";
        IdleAction = "ignore";
      };
    };

    lorri = {
      enable = true;
    };

    openssh = {
      enable = true;
    };

    tailscale = {
      enable = true;
      authKeyFile = config.sops.secrets."tailscale/authkey".path;
    };

    libinput = {
      enable = true;
    };

    printing = {
      enable = true;
    };

    hypridle = {
      enable = isHyprland;
    };

    fprintd = {
      enable = true;
    };

    pulseaudio = {
      enable = false;
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    xserver = {
      enable = isX11;

      xkb = {
        inherit (principal.keyboard) layout variant;
      };
    };
  };

  sops = {
    age = {
      keyFile = mkPathLiteral "/" ["var" "lib" "sops-nix" "key.txt"];
      generateKey = true;
    };
    secrets = {
      "tailscale/authkey" = {
        sopsFile = mkPathLiteral ./. ["secrets.yaml"];
        owner = "root";
        group = "root";
        mode = "0400";
      };
    };
  };

  system = {
    inherit (host.args) stateVersion;
    activationScripts = {
      konsole = {
        text = let
          mkProfile = user: mode: let
            flavor = host.aesthetics.users.${user.name}.theme.${mode}.flavor;
            destDir = "${user.paths.roots.home}/.local/share/konsole";
            destFile = "${destDir}/Catppuccin-${capitalize mode}.profile";
            content = writeText "catppuccin-${mode}-${user.name}.profile" ''
              [Appearance]
              ColorScheme=Catppuccin-${capitalize flavor}
              Font=monospace,18

              [General]
              Name=Catppuccin-${capitalize mode}
              Parent=FALLBACK/

              [Interaction Options]
              AutoCopySelectedText=true
            '';
          in ''
            install -D -m 0644 -o ${user.name} -g users ${content} ${destFile}
          '';
        in
          concatStringsSep "\n" (
            concatMap
            (user: map (mode: mkProfile user mode) ["dark" "light"])
            (attrValues host.users.normal)
          );
      };
    };
    copySystemConfiguration = true;
  };

  systemd = {
    sleep.settings.Sleep = {
      AllowSuspend = false;
      AllowHibernation = false;
      AllowSuspendThenHibernate = false;
      AllowHybridSleep = false;
    };

    #? Native project roots for Git identity routing. These are created on
    #? activation (test/switch), not during the pure build.
    tmpfiles.rules = unique (
      concatMap
      (user:
        [
          "d ${user.paths.roots.home}/Projects 0755 ${user.name} users - -"
        ]
        ++ map
        (profile: "d ${user.paths.roots.home}/Projects/${profile.root} 0755 ${user.name} users - -")
        (user.git.profiles or []))
      (attrValues host.users.normal)
    );

    user.services = {
      desktop-commander-remote = {
        description = "Desktop Commander Remote Device";
        wantedBy = ["default.target"];
        after = ["network-online.target"];
        wants = ["network-online.target"];
        serviceConfig = {
          ExecStart = "${pkgs.nodejs_22}/bin/npx -y @wonderwhy-er/desktop-commander@0.2.52 remote";
          Restart = "on-failure";
          RestartSec = 5;
        };
      };

      darkman = {
        description = "Dark/light mode switch daemon";
        wantedBy = ["default.target"];
        environment = with host.localization; {
          DARKMAN_LAT = toString latitude;
          DARKMAN_LNG = toString longitude;
        };
        serviceConfig = {
          ExecStart = "${bins.darkman} run";
          Restart = "on-failure";
        };
      };

      foot-server = {
        description = "foot terminal server";
        wantedBy = ["default.target"];
        after = ["darkman.service"];
        wants = ["darkman.service"];
        enableDefaultPath = false;
        serviceConfig = with bins; {
          ExecStart = "${writeShellScript "foot-server-start" ''
            theme="$(${darkman} get 2>/dev/null || echo dark)"
            exec ${foot} --server -o main.initial-color-theme="$theme"
          ''}";
          Restart = "on-failure";
        };
      };
    };
  };

  time = {
    timeZone = host.localization.timeZone or "America/Jamaica";
  };

  users = {
    users = host.users.core;
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {inherit host;};
    users = mapAttrs (name: user: let
      username = name;
      homeDirectory = user.paths.roots.home;
      inherit (host.args) stateVersion;
    in
      {config, ...}: {
        imports = with modules.home; [
          hermes-agent
          sops
        ];
        home = {
          inherit username homeDirectory stateVersion;
          packages = flatten (with host.packages; (
            forInterface
            ++ (map (app: pkgs.${app}) (user.apps or []))
            ++ (map (env: forShells.${env} or []) user.shells)
            ++ (map (dev: forCoding.${dev} or []) (user.coding or []))
          ));
        };

        programs = {
          hermes-agent = {
            enable = true;
            desktop.enable = true;
          };
        };

        services = {
          hermes-agent = {
            enable = true;
            gateway.enable = true;
            settings = {
              model = let
                models = {
                  deepseek-openrouter = {
                    default = "deepseek/deepseek-v4-flash:free";
                    provider = "openrouter";
                    base_url = "https://openrouter.ai/api/v1";
                  };
                  deepseek-nous = {
                    default = "deepseek/deepseek-v4-flash:free";
                    provider = "nous";
                    base_url = "https://inference-api.nousresearch.com/v1";
                  };
                  deepseek-ollama = {
                    default = "deepseek-r1:1.5b";
                    provider = "ollama";
                    base_url = "http://localhost:11434/v1";
                  };
                  openrouter-free = {
                    default = "openrouter/free";
                    provider = "openrouter";
                    base_url = "https://openrouter.ai/api/v1";
                  };
                };
              in
                models.openrouter-free;
            };
            environmentFiles = [
              config.sops.secrets."hermes/env".path
            ];
          };
        };

        sops = {
          age.keyFile = mkPath homeDirectory [".config" "sops" "age" "keys.txt"];
          secrets = {
            "hermes/env" = {
              sopsFile = mkPathLiteral ./. ["users" username "secrets.yaml"];
            };
          };
        };
      })
    host.users.normal;
  };
}
