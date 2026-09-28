{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit
    (lib.attrsets)
    attrByPath
    attrNames
    attrValues
    filterAttrs
    getAttr
    isAttrs
    listToAttrs
    mapAttrs
    mapAttrsToList
    optionalAttrs
    recursiveUpdate
    ;
  inherit
    (lib.lists)
    concatMap
    flatten
    head
    intersectLists
    isList
    optional
    optionals
    toList
    unique
    ;
  inherit (lib.modules) mkForce mkIf;
  inherit
    (lib.strings)
    concatMapStringsSep
    concatStringsSep
    escapeShellArg
    isString
    readFile
    splitString
    stringLength
    substring
    toLower
    toUpper
    trim
    ;
  inherit (pkgs) fetchgit runCommand writeShellApplication writeShellScript;
  inherit (pkgs.stdenv.hostPlatform) isLinux isDarwin;

  capitalize = str: toUpper (substring 0 1 str) + substring 1 (-1) str;
  mkPath = root: stems: root + "/" + (concatStringsSep "/" stems);
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

  args = let
    # src = import ./.;
    src = let
      arch = "x86_64";
      os = "linux";
      admin = "craole";
    in {
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
          src = "/home/${admin}/Projects/dotDots";
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
          uid = 1000;
          enable = true;
          autoLogin = false;
          role = "administrator";
          hashedPassword = "$y$j9T$PJC1IvldG.uplQOvWOf7d.$k9jqsgqFEXJzfc1I4nuvrIOl9z/X3xLBEzvJPExXYoC";
          description = "Craig 'Craole' Cole";
          defaultLocale = "en_GB.UTF-8";
          keyboard = {
            layout = "us";
            variant = "";
          };

          git = let
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
                directory = [args.paths.dots];
              };
              url = {
                "https://github.com/".insteadOf = ["gh:" "github:"];
              };
            };
          in [
            {
              name = "craole-cc";
              email = "134658831+craole-cc@users.noreply.github.com";
              inherit settings;
            }
            {
              name = "Craole";
              email = "32288735+Craole@users.noreply.github.com";
              inherit settings;
            }
          ];
          desktop = "plasma";
          launchers = ["vicinae"];
          theme = {
            autoSwitch = true;
            polarity = "dark";
            dark = {
              flavor = "frappe";
              accent = "teal";
            };
            light = {
              flavor = "latte";
              accent = "mauve";
            };
          };
          icons = {
            light = "buuf-nestort";
            dark = "candy-icons";
          };
          cursors = {
            accent = "teal";
            dark = "material";
            light = "material";
          };
          fonts = {
            emoji = "Noto Color Emoji";
            monospace = "Maple Mono NF";
            sans = "Monaspace Radon Frozen";
            serif = "Noto Serif";
            material = "Material Symbols Sharp";
            clock = "Rubik";
          };
          shells = [
            "bash"
            "nushell"
            "powershell"
            "zsh"
          ];
          coding = [
            "common"
            "nix"
            "markup"
            "rust"
            "python"
            "shellscript"
            "zig"
          ];
          apps = [
            "brave"
            "freetube"
            "ghostty"
            "imv"
            "qbittorrent-enhanced"
            "qimgv"
            "shortwave"
            "vscode-fhs"
          ];
        }
      ];
    };

    inputs = src.lix.inputs or (src.inputs or (lib.flakes.inputs or null));
    users = let
      normalize = user: let
        home = "/home/${user.name}";
        shells = user.shells or ["bash"];
        role = user.role or "normal";
        isNormalUser = role != "service";
      in
        user
        // {
          inherit role shells isNormalUser;
          isSystemUser = !isNormalUser;
          paths =
            user.paths or {
              inherit home;
              inherit (args.paths.roots) src;
              cfg = {
                source = "${args.paths.roots.src}/Configuration";
                target = "${home}/.config";
              };
            };
        }
        // optionalAttrs isNormalUser {
          defaultLocale = user.defaultLocale or
          args.localization.defaultLocale;
          keyboard =
            recursiveUpdate {
              layout = "us";
              variant = "";
            }
            (user.keyboard or {});
        };

      normalized =
        mapAttrs
        (_: normalize) (
          listToAttrs (
            map (value: {
              inherit value;
              inherit (value) name;
            })
            (src.principals or {})
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
              inherit (user) hashedPassword isNormalUser isSystemUser name;
              extraGroups =
                optionals
                (user.role == "administrator") ["networkmanager" "wheel"];
              shell = getAttr (head user.shells) pkgs;
            }
            // optionalAttrs (user ? password) {inherit (user) password;}
            // optionalAttrs (user ? uid) {inherit (user) uid;}
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

    localization = recursiveUpdate {
      latitude = 18.015;
      longitude = -77.49;
      city = "Mandeville, Jamaica";
      timeZone = "America/Jamaica";
      defaultLocale = "en_US.UTF-8";
    } (src.localization or {});

    paths =
      recursiveUpdate
      {dots = args.paths.roots.src;}
      (src.paths or {});
  in
    src // {inherit inputs users paths localization;};

  sources = let
    inherit (args) inputs;
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
    normalize = {
      owner,
      repo,
      rev,
      sha256 ? null,
      type ? "github",
    }: {
      inherit type owner repo rev sha256;
      url = "https://github.com/${owner}/${repo}/archive/${rev}.tar.gz";
    };

    #? Uses sha256 when provided (reproducible), or fetches raw tarball when omitted/null (unpinned)
    fetchSrc = src:
      if src ? sha256 && src.sha256 != null && src.sha256 != ""
      then fetchTarball {inherit (src) url sha256;}
      else fetchTarball src.url;

    fetchMod = {
      name,
      path ? null,
      default ? null,
      enabled ? true,
    }:
      if !enabled
      then {} #? Returns an empty valid module!
      else if inputs ? ${name}
      then inputs.${name}.nixosModules.${name} or inputs.${name}
      else let
        fetched = fetchSrc revision.${name};
      in
        if path != null
        then import "${fetched}/${path}"
        else default fetched;

    revision = {
      nixpkgs = normalize {
        owner = "NixOS";
        repo = "nixpkgs";
        rev = "20b1ddd1aa5ace70c9468305030aa4f9ef79671b";
        sha256 = "sha256-B44WL6h0XoLjJ41bUPJk0X5SDinLCII//6EcBLXKiJ0=";
      };

      home-manager = normalize {
        owner = "nix-community";
        repo = "home-manager";
        rev = "4900baf1e219645e4a2acba35723852b2091bc20";
        sha256 = "sha256-BOyZoliWfm/beS4m3FxFKlu5at6npZen1PsWtvzzihk=";
      };

      dots = normalize {
        owner = "craole-cc";
        repo = "dotDots";
        rev = "main";
      };

      nix-index = normalize {
        owner = "nix-community";
        repo = "nix-index-database";
        rev = "9ad722673ab3b3f91f02135e53775825b240b869";
        sha256 = "sha256-Dkg4VKPmDPqTwaiw2WH5br73tXoL1qrOO0xJnR4TlcA=";
      };

      catppuccin = normalize {
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

    modules = {
      nixpkgs = let
        config' = {allowUnfree = true;};
      in
        if inputs ? nixpkgs
        then
          import inputs.nixpkgs {
            inherit (args) system;
            config = config';
          }
        else import (fetchSrc revision.nixpkgs) {config = config';};

      home-manager = fetchMod {
        name = "home-manager";
        path = "nixos";
      };

      dots =
        inputs.dots or (fetchSrc revision.dots);

      catppuccin = fetchMod {
        name = "catppuccin";
        path = "modules/nixos";
      };

      nix-index = fetchMod {
        name = "nix-index";
        path = "nixos-module.nix";
      };

      icons = let
        papirus = with modules.nixpkgs;
          catppuccin-papirus-folders.override {
            inherit (aesthetics.primary.theme.dark) flavor accent;
          };
      in {
        buuf-nestort = with modules.nixpkgs;
          stdenvNoCC.mkDerivation {
            pname = "buuf-nestort";
            version = "2026-07-29";
            src = fetchgit {inherit (revision.buuf-nestort) url rev hash;};
            dontBuild = true;
            dontFixup = true;
            installPhase = ''
              mkdir -p $out/share/icons/buuf-nestort
              cp -r . $out/share/icons/buuf-nestort
              chmod -R u+w $out/share/icons/buuf-nestort
              sed -i 's/^Inherits=.*/Inherits=oxygen,breeze,Adwaita,hicolor/' \
                $out/share/icons/buuf-nestort/index.theme
            '';
          };
        Papirus-Dark = papirus;
        Papirus-Light = papirus;
      };

      catppuccin-konsole = let
        flavors = unique (
          concatMap
          (user: with user.theme; [dark.flavor light.flavor])
          (attrValues aesthetics.users)
        );
        pname = "catppuccin-konsole";
      in
        with modules.nixpkgs;
          stdenvNoCC.mkDerivation {
            inherit pname;
            version = "3b64040";
            src = fetchFromGitHub {
              inherit (revision.${pname}) owner repo rev hash;
            };
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
    modules // {inherit revision;};

  interface = let
    normalized = map toLower (args.interface.desktops or []);

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
      defaultSession = args.principal.desktop or "plasma";
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
          (args.interface.theme or {})
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
          (args.interface.icons or {})
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
    with args.users; {
      inherit of;
      primary = of principal;
      users = mapAttrs (_: of) normal;
    };

  variables = let
    inherit (args) name paths;
    inherit (args.users) principal;
    stems = {
      cfg = "/Configuration";
      host = "/${name}";
      hosts = "/API/nix/hosts";
    };
    env = variables;
    HOST = name;
  in {
    #~@ Paths
    DOTS_STORE = sources.dots;
    DOTS_LOCAL = paths.roots.src;
    DOTS_BUILD = paths.roots.run;
    DOTS = env.DOTS_LOCAL;
    DOTS_HOSTS = env.DOTS_LOCAL_HOSTS;
    DOTS_LOCAL_HOSTS = env.DOTS_LOCAL + stems.hosts;
    DOTS_STORE_HOSTS = env.DOTS_STORE + stems.hosts;
    "DOTS_LOCAL_HOST_${HOST}" = env.DOTS_LOCAL_HOSTS + stems.host;
    "DOTS_STORE_HOST_${HOST}" = env.DOTS_STORE_HOSTS + stems.host;
    DOTS_STORE_CFG = env.DOTS_STORE + stems.cfg;
    DOTS_LOCAL_CFG = env.DOTS_LOCAL + stems.cfg;

    #~@ Inputs
    REV_URL_CORE = sources.revision.nixpkgs.url;
    REV_URL_HOME = sources.revision.home-manager.url;
    REV_URL_INDEX = sources.revision.nix-index.url;
    REV_URL_CATPPUCCIN = sources.revision.catppuccin.url;
    REV_URL_DOTS = sources.revision.dots.url;

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
    #? Per-shell packages, pulled into a user's own profile (home.packages)
    #? based on that user's `shells` list in default.nix — never installed
    #? system-wide.
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
            script = mkPath sources.dots [
              "Libraries"
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
            pkg = stdenvNoCC.mkDerivation {
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

    #? Per-language/tooling packages, pulled into a user's own profile
    #? (home.packages) based on that user's `coders` list in default.nix —
    #? never installed system-wide. Add new categories here as needed.
    forCoding = {
      common = with pkgs; [
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
        glib
        glib
        gnused
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
        sad
        speedtest-go
        systemd
        trashy
        treefmt
        udiskie
        usbutils
        uutils-coreutils-noprefix
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
          yamlfmt
        ]
        ++ (with typstPackages; [typsy]);

      nix = with pkgs; [
        alejandra
        cachix
        lorri
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
              sources.dots
              + "/Libraries/posix/project/formatters/shflint"
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

    forInterface =
      (with pkgs; [adwaita-icon-theme])
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
        sources.catppuccin-konsole
        yakuake
      ])
      ++ map
      (name: sources.icons.${name} or pkgs.${name})
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
            ${bins.dconfGnomeInterface}/color-scheme "'prefer-${mode}'"
            ${bins.dconfGnomeInterface}/gtk-theme "'${theme.gtk}'"
            ${bins.dconfGnomeInterface}/icon-theme "'${icon}'"

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
                    (attrValues args.users.normal);

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
              THEME_KDE_LIGHT = variables.THEME_KDE_LIGHT;
              THEME_KDE_DARK = variables.THEME_KDE_DARK;
              THEME_GTK_LIGHT = variables.THEME_GTK_LIGHT;
              THEME_GTK_DARK = variables.THEME_GTK_DARK;
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
              THEME_ICONS_LIGHT = variables.THEME_ICONS_LIGHT;
              THEME_ICONS_DARK = variables.THEME_ICONS_DARK;
            };
            mkAssigns = vals:
              concatStringsSep "\n" (mapAttrsToList (key: value: "${key}=${escapeShellArg value};") vals);
            #? Single source of truth: whatever's assigned above, plus the two derived scheme vars.
            exported =
              (attrNames fallback) ++ (attrNames static) ++ ["THEME_KDE_SCHEME_LIGHT" "THEME_KDE_SCHEME_DARK"];
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

            ${readFile (mkPath sources.dots [
              "Libraries"
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
                readFile (mkPath sources.dots [
                  "Libraries"
                  "posix"
                  "packages"
                  "manager"
                  "nix"
                  "nixos-switch.sh"
                ])
              }
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

  bins = let
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
    paths = listToAttrs (map mkBin [
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
        name = "dconfGnomeInterface";
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
    ]);
  in
    paths;
in {
  imports = with sources; [
    ./hardware-configuration.nix
    home-manager
    nix-index
    catppuccin
  ];

  boot = {
    loader = with interface.boot.loader; {
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
      pkgs.${args.packages.kernel or "linuxPackages_latest"};
  };

  catppuccin = {
    enable = true;
    autoEnable = true;
    inherit (aesthetics.primary.active) flavor accent;
  };

  console = {
    keyMap = args.users.principal.keyboard.layout;
  };

  documentation = {
    nixos.enable = false;
  };

  environment = {
    pathsToLink = mkIf interface.isPlasma ["/share/konsole"];
    plasma6.excludePackages = with pkgs.kdePackages; [
      khelpcenter
      # elisa
      # gwenview
    ];
    sessionVariables = variables;
    systemPackages = packages.complete;
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
    inherit (args.users.principal) defaultLocale;
  };

  networking = {
    hostName = args.name;
    hostId = args.id;
    networkmanager.enable = true;
  };

  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    nixPath = [
      "nixos-config=${variables.DOTS_BUILD}/configuration.nix"
      "nixpkgs=${sources.nixpkgs.path}"
    ];
  };

  nixpkgs = {
    pkgs = sources.nixpkgs;
  };

  programs = {
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
              config = let
                stems = ["Configuration" "foot"];
              in {
                local = mkPath args.paths.roots.src stems;
                store = mkPath sources.dots stems;
              };

              themes = {
                pkgs = mkPath pkgs.foot.themes ["share" "foot" "themes"];
                dots = mkPath dirs.config.local ["themes"];
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
            (mkPath dirs.config.local ["config.ini"])
          ];
        };
        mouse = {
          hide-when-typing = "yes";
        };
      };
    };

    git = let
      profiles = args.users.principal.git;
      profile =
        if isNotEmpty profiles
        then head profiles
        else null;
      hasProfile = profile != null;
    in {
      enable = hasProfile;
      lfs = {
        enable = true;
        enablePureSSHTransfer = true;
      };
      prompt.enable = true;
      config =
        profile.settings
        // {
          user = mkIf hasProfile {inherit (profile) user email;};
        };
    };

    hyprland = {
      enable = interface.isHyprland;
      withUWSM = true;
    };

    hyprlock = {
      enable = interface.isHyprland;
    };

    iio-hyprland = {
      enable = interface.isHyprland;
    };

    kbdlight = {
      enable = true;
    };

    kdeconnect = {
      enable = true;
    };

    labwc = {
      enable = interface.isLab;
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
      enable = interface.isMango;
    };

    nh = {
      enable = true;
      clean = {
        enable = true;
        extraArgs = "--keep-since 7d --keep 3";
      };
      flake = args.paths.dots;
    };

    niri = {
      enable = interface.isNiri;
    };

    nix-index = {
      enable = true;
      # comma.enable = true;
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
        sources.dots + "/Configuration/starship/config.toml"
      ));
    };
  };

  security = {
    sudo.extraRules = [
      {
        users = [args.users.principal.name];
        commands = [
          {
            command = "ALL";
            options = ["NOPASSWD"];
          }
        ];
      }
    ];

    rtkit.enable = true;
  };

  services = {
    displayManager = {
      enable = true;
      defaultSession = mkForce (
        if interface.isPlasma
        then "plasma"
        else if interface.isNiri
        then "niri"
        else interface.defaultSession
      );

      autoLogin = {
        inherit (args.users.autoLogin) enable user;
      };

      plasma-login-manager = {
        enable = interface.isPlasma;
      };
    };

    desktopManager = {
      plasma6 = {
        enable = interface.isPlasma;
      };

      gnome = {
        enable = interface.isGnome;
      };

      cosmic = {
        enable = interface.isCosmic;
      };
    };

    xserver = {
      enable = interface.isX11;

      xkb = {
        inherit (args.users.principal.keyboard) layout variant;
      };
    };

    openssh = {
      enable = true;
    };

    tailscale = {
      enable = true;
    };

    libinput = {
      enable = true;
    };

    printing = {
      enable = true;
    };

    hypridle = {
      enable = interface.isHyprland;
    };

    fprintd = {
      enable = true;
    };

    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };

  system = {
    inherit (args) stateVersion;
    activationScripts = {
      konsole = {
        text = let
          mkProfile = user: mode: let
            flavor = aesthetics.users.${user.name}.theme.${mode}.flavor;
            destDir = "${user.paths.home}/.local/share/konsole";
            destFile = "${destDir}/Catppuccin-${capitalize mode}.profile";
            content = pkgs.writeText "catppuccin-${mode}-${user.name}.profile" ''
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
            (attrValues args.users.normal)
          );
      };
    };
    copySystemConfiguration = true;
  };

  systemd = {
    user.services = {
      darkman = {
        description = "Dark/light mode switch daemon";
        wantedBy = ["default.target"];
        environment = with args.localization; {
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
    timeZone = args.localization.timeZone or "America/Jamaica";
  };

  users = {
    users = args.users.core;
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {host = args;};
    users =
      mapAttrs (name: user: {
        home = {
          inherit (args) stateVersion;
          username = user.name;
          homeDirectory = user.paths.home;
          #~@ Shell/dev tooling lives in the user's own profile, opted into
          #~@ via `shells`/`codes` in default.nix, rather than system-wide.
          packages = flatten (with packages; (
            forInterface
            ++ (map (app: pkgs.${app}) (user.apps or []))
            ++ (map (env: forShells.${env} or []) user.shells)
            ++ (map (dev: forCoding.${dev} or []) (user.coding or []))
          ));
        };
      })
      args.users.normal;
  };
}
