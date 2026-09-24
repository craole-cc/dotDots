{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) attrNames attrValues filterAttrs getAttr isAttrs listToAttrs mapAttrs optionalAttrs recursiveUpdate;
  inherit (lib.lists) concatMap flatten head intersectLists isList optional optionals unique;
  inherit (lib.modules) mkForce mkIf;
  inherit (lib.strings) concatMapStringsSep isString readFile stringLength substring toLower toUpper trim;
  inherit (pkgs) fetchgit writeShellApplication;
  inherit (pkgs.stdenv.hostPlatform) isLinux isDarwin;

  capitalize = str: toUpper (substring 0 1 str) + substring 1 (-1) str;

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
    src = import ./.;
  in
    src
    // {
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
                inherit (paths.roots) src;
                cfg = {
                  source = "${paths.roots.src}/Configuration";
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
                inherit (user) isNormalUser isSystemUser name;
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

      paths = let
        roots = {
          src = "/home/craole-cc/Projects/dotDots";
          run = "/etc/nixos";
        };
        dots = paths.roots.src;
      in
        recursiveUpdate {inherit roots dots;} (src.paths or {});

      inputs = src.inputs or null;

      # inherit interface sources variables packages;
    };
  inherit (args) inputs id localization name paths stateVersion users;
  inherit (args.users) principal;

  sources = let
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

    packages = {
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
        papirus = with packages.nixpkgs;
          catppuccin-papirus-folders.override {
            inherit (aesthetics.primary.theme.dark) flavor accent;
          };
      in {
        buuf-nestort = with packages.nixpkgs;
          stdenvNoCC.mkDerivation {
            pname = "buuf-nestort";
            version = "2026-07-29";
            src = fetchgit {inherit (revision.buuf-nestort) url rev hash;};
            dontBuild = true;
            dontFixup = true;
            installPhase = ''
              mkdir -p $out/share/icons/buuf-nestort
              cp -r . $out/share/icons/buuf-nestort
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
        with packages.nixpkgs;
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
    packages // {inherit revision;};

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
      defaultSession = principal.desktop or "plasma";
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
  in {
    inherit of;
    primary = of principal;
    users = mapAttrs (_: of) users.normal;
  };
  variables = let
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

        (writeShellApplication {
          name = "pwshfmt";
          runtimeInputs = [powershell];
          text = ''
            export PSModulePath="${let
              pname = "PSScriptAnalyzer";
              version = "1.25.0";
            in
              stdenvNoCC.mkDerivation {
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
              }}/share/powershell/Modules''${PSModulePath:+:$PSModulePath}"

            exec pwsh \
              -NoProfile \
              -NonInteractive \
              -File ${sources.dots + "/Libraries/powershell/Admin/pwshfmt.ps1"} \
              "$@"
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
        diffutils
        dua
        dust
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
        gnused
        gum
        glib
        procs
        glib
        helix
        imagemagick
        imv
        jq
        jql
        lolcat
        lsd
        lshw
        dbus
        glib
        gnused
        procps
        systemd
        onefetch
        ouch
        p7zip
        patch
        pciutils
        pkg-config
        procs
        procps
        ripgrep
        rsync
        sad
        speedtest-go
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
      optionals (with interface; isX11 || isWayland) (with pkgs; [
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
        kio
        yakuake
        kconfig
        plasma-workspace
      ])
      ++ map
      (name: sources.icons.${name} or pkgs.${name})
      (unique (
        concatMap
        (elements: with elements.icons; [dark light])
        (attrValues aesthetics.users)
      ))
      ++ (let
        perUser = attrValues aesthetics.users;
      in [
        (pkgs.catppuccin-kde.override {
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
      ])
      ++ [
        (writeShellApplication {
          name = "theme-toggle";
          runtimeInputs = with pkgs; [coreutils libnotify];
          bashOptions = [];
          text = ''
            #> Use the DMS-generated Matugen schemes only while DMS is running;
            if
              command -v dms >/dev/null 2>&1 &&
                dms ipc call theme getMode >/dev/null 2>&1
            then
              THEME_KDE_LIGHT="DankMatugenLight";
              THEME_KDE_DARK="DankMatugenDark";
              THEME_GTK_LIGHT="DankMatugenLight";
              THEME_GTK_DARK="DankMatugenDark";
            else
              THEME_KDE_LIGHT="${variables.THEME_KDE_LIGHT}";
              THEME_KDE_DARK="${variables.THEME_KDE_DARK}";
              THEME_GTK_LIGHT="${variables.THEME_GTK_LIGHT}";
              THEME_GTK_DARK="${variables.THEME_GTK_DARK}";
            fi

            THEME_ICONS_LIGHT="${variables.THEME_ICONS_LIGHT}";
            THEME_ICONS_DARK="${variables.THEME_ICONS_DARK}";
            THEME_KDE_SCHEME_LIGHT="$THEME_KDE_LIGHT";
            THEME_KDE_SCHEME_DARK="$THEME_KDE_DARK";

            export \
              THEME_KDE_SCHEME_LIGHT \
              THEME_KDE_LOOKANDFEEL_LIGHT \
              THEME_KDE_SCHEME_DARK \
              THEME_KDE_LOOKANDFEEL_DARK \
              THEME_KDE_LIGHT \
              THEME_KDE_DARK \
              THEME_GTK_LIGHT \
              THEME_GTK_DARK \
              THEME_ICONS_LIGHT \
              THEME_ICONS_DARK

            ${readFile (
              sources.dots
              + "/Libraries/posix/interface/theme/theme-switch.sh"
            )}
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
            text = with variables; ''
              export DOTS="${DOTS}"
              export DOTS_BUILD="${DOTS_BUILD}"
              export DOTS_HOSTS="${DOTS_HOSTS}"
              export HOST="${HOST}"
              export REV_URL_CORE="${REV_URL_CORE}"
              export REV_URL_HOME="${REV_URL_HOME}"
              export REV_URL_INDEX="${REV_URL_INDEX}"
              export REV_URL_CATPPUCCIN="${REV_URL_CATPPUCCIN}"
              export REV_URL_DOTS="${REV_URL_DOTS}"
              ${readFile (sources.dots + "/Libraries/posix/packages/manager/nix/nixos-switch.sh")}
            '';
          })
        ]
    );
  in {inherit forShells forCoding forInterface forSystem;};
in {
  imports = with sources; [
    ./hardware-configuration.nix
    home-manager
    nix-index
    catppuccin
  ];

  boot = {
    loader = with interface.boot.loader; {
      grub = {
        inherit device;
        enable = manager == "grub";
        useOSProber = true;
        fsIdentifier = "provided";
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
    keyMap = principal.keyboard.layout;
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
    systemPackages = packages.forSystem;
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
    inherit (principal) defaultLocale;
  };

  networking = {
    hostName = name;
    hostId = id;
    networkmanager.enable = true;
  };

  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    nixPath = [
      "nixos-config=${variables.DOTS_BUILD}"
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

    direnv = {
      enable = true;
      silent = true;
      angrr = {
        enable = true;
      };
    };

    git = {
      enable = true;
      lfs = {
        enable = true;
        enablePureSSHTransfer = true;
      };
      prompt.enable = true;
      config = {
        user = {inherit (principal) email name;};
        init.defaultBranch = "main";
        safe.directory = [paths.dots];
        url."https://github.com/".insteadOf = ["gh:" "github:"];
        alias.project-summary = "!which onefetch && onefetch";
        push.autoSetupRemote = true;
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
      flake = paths.dots;
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
        users = [principal.name];
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
        inherit (users.autoLogin) enable user;
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
        inherit (principal.keyboard) layout variant;
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
    inherit stateVersion;
  };

  time = {
    timeZone = args.localization.timeZone or "America/Jamaica";
  };

  users.users = users.core;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {host = args;};
    users =
      mapAttrs (name: user: {
        home = {
          inherit stateVersion;
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
        services = {
          darkman = let
            # TODO: Should we make this a writeShellApplication
            inherit (aesthetics.users.${name}) icons kdeScheme;
            inherit (pkgs) dbus glib gnused procps systemd;
            inherit (pkgs.kdePackages) kconfig plasma-workspace;
            gds = pkgs.gsettings-desktop-schemas;
            konf = "${kconfig}/bin/kwriteconfig6";
            pkill = "${procps}/bin/pkill";
            jq = "${pkgs.jq}/bin/jq";
            busctl = "${systemd}/bin/busctl";
            sed = "${gnused}/bin/sed";
            pac = "${plasma-workspace}/bin/plasma-apply-colorscheme";
            gic = "${glib}/bin/gsettings set org.gnome.desktop.interface";
            dbusSend = "${dbus}/bin/dbus-send";
            mkScript = mode: let
              MODE = toUpper mode;
              theme = {
                kde = kdeScheme.${mode};
                gtk = variables."THEME_GTK_${MODE}";
              };
              icon = icons.${mode};
              konsole = {
                profile = "Catppuccin ${capitalize mode}";
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
              XDG_DATA_DIRS=${gds}/share/gsettings-schemas/${gds.name}:$XDG_DATA_DIRS
              export XDG_DATA_DIRS

              ${pkill} -${foot.signal} -x foot || true

              ${konf} --file konsolerc --group "Desktop Entry" --key DefaultProfile ${konsole.profile}
              ${konf} --file yakuakerc --group "Desktop Entry" --key DefaultProfile ${konsole.profile}

              for terminal in $(${busctl} --user call org.kde.yakuake /yakuake/sessions org.kde.yakuake terminalIdList 2>/dev/null | ${sed} 's/^s "//; s/"$//; s/,/ /g'); do
                ${busctl} --user call org.kde.yakuake /Sessions/$((terminal + 1)) org.kde.konsole.Session setProfile s "${konsole.profile}" >/dev/null 2>&1 || true
              done
              ${pac} ${theme.kde}
              ${konf} --file kdeglobals --group Icons --key Theme ${icon}
              ${dbusSend} --session --type=signal /KIconLoader org.kde.KIconLoader.iconChanged int32:0
              ${gic} color-scheme 'prefer-${mode}'
              ${gic} gtk-theme '${theme.gtk}'
              ${gic} icon-theme '${icon}'
              ${procps}/bin/pkill -${foot.signal} -x foot || true

              #> Force VS Code's theme directly. Electron on Linux does not
              #> reliably re-evaluate org.freedesktop.appearance at runtime
              #> (microsoft/vscode#91169, #102795, #179431), so push the setting
              #> into settings.json instead, which VS Code's file-watcher does
              #> pick up live.
              ${
                concatMapStringsSep "\n" (dir: ''
                  vscodeSettings="$HOME/${dir}/settings.json"
                  if [ -d "$(dirname "$vscodeSettings")" ]; then
                    [ -f "$vscodeSettings" ] || echo '{}' > "$vscodeSettings"
                    ${jq} \
                      --arg theme "${vscode.theme}" \
                      '. + {"workbench.colorTheme": $theme, "window.autoDetectColorScheme": false}' \
                      "$vscodeSettings" > "$vscodeSettings.tmp" \
                      && mv "$vscodeSettings.tmp" "$vscodeSettings"
                  fi
                '')
                vscode.configDirs
              }
            '';
          in {
            enable = true;
            settings = with localization; {
              lat = latitude;
              lng = longitude;
            };
            darkModeScripts.theme = mkScript "dark";
            lightModeScripts.theme = mkScript "light";
          };
        };
      })
      users.normal;
  };
}
