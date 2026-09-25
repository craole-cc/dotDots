{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit
    (lib.attrsets)
    attrNames
    attrValues
    filterAttrs
    getAttr
    isAttrs
    listToAttrs
    mapAttrs
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
    unique
    ;
  inherit (lib.modules) mkForce mkIf;
  inherit
    (lib.strings)
    concatMapStringsSep
    isString
    readFile
    stringLength
    substring
    toLower
    toUpper
    trim
    ;
  inherit (pkgs) writeShellApplication;
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
          shells = user.applications.shells or (user.shells or ["bash"]);
          apps =
            (user.applications.common or [])
            ++ (user.applications.launchers or [])
            ++ (user.apps or []);
          coding = user.applications.coding or (user.coding or []);
          role = user.role or "normal";
          isNormalUser = role != "service";
        in
          user
          // {
            inherit role shells apps coding isNormalUser;
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
              (src.principals or [])
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

        principal = normalized.${(head (builtins.filter (p: p.enable or false) (src.principals or []))).name};

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
        dots = roots.src;
      in
        recursiveUpdate {inherit roots dots;} (src.paths or {});

      inputs = src.inputs or null;
    };
  inherit (args) inputs id localization name paths stateVersion users;
  inherit (args.users) principal;

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
      #? craole.nix names this `desktops` (plural, a preference-ordered
      #? list), matching interface.desktops rather than a singular
      #? `desktop`; take the first entry, guarding against an empty list.
      defaultSession = head ((principal.desktops or normalized) ++ ["plasma"]);
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
          #? craole.nix nests the palette definitions under theme.palettes.*
          #? rather than directly under theme.*; mirror that shape so a
          #? principal that only overrides theme.dark/theme.light still gets
          #? these as the default palette source.
          palettes = {
            frappe = {
              #~@ Metadata
              name = "Catppuccin Frappé";
              slug = "catppuccin-frappe";
              description = "Soft dark theme with muted tones";
              variant = "dark";
              icon = "icons/catppuccin-frappe.png";

              #~@ Core Base Colors
              base = "#303446";
              mantle = "#292c3c";
              crust = "#232634";

              #~@ Text & Subtext
              text = "#c6d0f5";
              subtext1 = "#b5bfe2";
              subtext0 = "#a5adce";

              #~@ UI Surfaces & Overlays
              surface0 = "#414559";
              surface1 = "#51576d";
              surface2 = "#626880";
              overlay0 = "#737994";
              overlay1 = "#838ba7";
              overlay2 = "#949cbb";

              #~@ Accents
              rosewater = "#f2d5cf";
              flamingo = "#eebebe";
              pink = "#f4b8e4";
              mauve = "#ca9ee6";
              red = "#e78284";
              maroon = "#ea999c";
              peach = "#ef9f76";
              yellow = "#e5c890";
              green = "#a6d189";
              teal = "#81c8be";
              sky = "#99d1db";
              sapphire = "#85c1dc";
              blue = "#8caaee";
              lavender = "#babbf1";
            };

            latte = {
              #~@ Metadata
              name = "Catppuccin Latte";
              slug = "catppuccin-latte";
              description = "Cozy light theme with color-rich accents";
              variant = "light";
              icon = "icons/catppuccin-latte.png";

              #~@ Core Base Colors
              base = "#eff1f5";
              mantle = "#e6e9ef";
              crust = "#dce0e8";

              #~@ Text & Subtext
              text = "#4c4f69";
              subtext1 = "#5c5f77";
              subtext0 = "#6c6f85";

              #~@ UI Surfaces & Overlays
              surface0 = "#ccd0da";
              surface1 = "#bcc0cc";
              surface2 = "#acb0be";
              overlay0 = "#9ca0b0";
              overlay1 = "#8c8fa1";
              overlay2 = "#7c7f93";

              #~@ Accents
              rosewater = "#dc8a78";
              flamingo = "#dd7878";
              pink = "#ea76cb";
              mauve = "#8839ef";
              red = "#d20f39";
              maroon = "#e64553";
              peach = "#fe640b";
              yellow = "#df8e1d";
              green = "#40a02b";
              teal = "#179299";
              sky = "#04a5e5";
              sapphire = "#209fb5";
              blue = "#1e66f5";
              lavender = "#7287fd";
            };
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
          #? craole.nix sets these per-mode under theme.dark.icons /
          #? theme.light.icons rather than a separate top-level `icons`
          #? attr; fall back to that, then to Papirus if neither is set.
          dark = theme.dark.icons or "Papirus-Dark";
          light = theme.light.icons or "Papirus-Light";
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
  #? Bare `palettes` is referenced further down (vicinae themes, foot colors)
  #? for the principal's flavor set; keep it here rather than re-deriving
  #? aesthetics.primary.theme.palettes at each call site.
  palettes = aesthetics.primary.theme.palettes;

  #? sources.nix was split out but never actually imported: every
  #? `sources.*` reference below (imports, sources.dots, sources.icons,
  #? sources.catppuccin-konsole, the nixPath entry) was an undefined
  #? variable. Depends on aesthetics (icon/konsole packages are keyed off
  #? the configured flavor/accent per user), so it's bound after it.
  sources = import ./sources.nix {
    inherit pkgs inputs aesthetics;
    system = args.system;
    lib = recursiveUpdate lib {strings = {inherit capitalize;};};
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
      ++ optional interface.isNiri (with pkgs; [alacritty fuzzel])
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
        #? One `git-profile NAME` per identity in principal.git, in list
        #? order (the head is also what `programs.git` applies globally).
        #? Only sets `--local` config, so it's scoped to the repo you're in.
        #? craole.nix's entries carry no directory, so this is a manual
        #? switch rather than an automatic `includeIf`; add a `path` to an
        #? entry and wire up `programs.git.includes` if you want that later.
        ++ optionals (isNotEmpty (principal.git or [])) (let
          #? `push.autoSetupRemote = true;` is nested-attrset sugar for
          #? `push = { autoSetupRemote = true; };`, not a flat dotted key,
          #? so flatten to the dotted paths `git config` actually wants.
          flattenSettings = prefix: attrs:
            concatMap (
              k: let
                v = attrs.${k};
                path =
                  if prefix == ""
                  then k
                  else "${prefix}.${k}";
              in
                if isAttrs v
                then flattenSettings path v
                else [
                  {
                    inherit path;
                    value = v;
                  }
                ]
            ) (attrNames attrs);
        in [
          (writeShellApplication {
            name = "git-profile";
            runtimeInputs = with pkgs; [git];
            text = ''
              usage() {
                cat <<'EOF'
              usage: git-profile [NAME]

              Set user.name/user.email (and any per-profile git config) for
              the CURRENT repository only. With no argument, lists the
              configured profiles in priority order (first = global default).
              EOF
              }

              list_profiles() {
                cat <<'EOF'
              ${concatMapStringsSep "\n" (p: "${p.name} <${p.email}>") principal.git}
              EOF
              }

              if [ "$#" -eq 0 ]; then
                list_profiles
                exit 0
              fi

              case "''${1:-}" in
                -h | --help)
                  usage
                  exit 0
                  ;;
              ${concatMapStringsSep "\n" (p: ''
                  "${p.name}")
                    git config user.name "${p.name}"
                    git config user.email "${p.email}"
                    ${concatMapStringsSep "\n" (
                    s: ''git config "${s.path}" "${toString s.value}"''
                  ) (flattenSettings "" (p.settings or {}))}
                    echo "Switched to ${p.name} <${p.email}> for $(git rev-parse --show-toplevel)"
                    ;;
                '')
                principal.git}
              *)
                echo "unknown profile: $1" >&2
                list_profiles >&2
                exit 1
                ;;
              esac
            '';
          })
        ])
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

    git = let
      #? craole.nix's `git` is a list, ordered by priority: the head is the
      #? identity actually applied globally. Falls back to the old
      #? top-level name/email if a principal has no `git` list at all.
      identities = principal.git or [{inherit (principal) name email;}];
      primary = head identities;
    in {
      enable = true;
      lfs = {
        enable = true;
        enablePureSSHTransfer = true;
      };
      prompt.enable = true;
      config =
        {
          user = {inherit (primary) name email;};
          init.defaultBranch = "main";
          safe.directory = [paths.dots];
          url."https://github.com/".insteadOf = ["gh:" "github:"];
        }
        // (primary.settings or {});
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
      mapAttrs (name: user: let
        aes = aesthetics.users.${name};
        modes = ["dark" "light"];

        #? Catppuccin colours for terminals that need an explicit palette (foot).
        #? Add macchiato/mocha here if you ever switch to those flavors.
        palette = {
          frappe = {
            rosewater = "f2d5cf";
            base = "303446";
            text = "c6d0f5";
            subtext0 = "a5adce";
            subtext1 = "b5bfe2";
            surface1 = "51576d";
            surface2 = "626880";
            red = "e78284";
            green = "a6d189";
            yellow = "e5c890";
            blue = "8caaee";
            pink = "f4b8e4";
            teal = "81c8be";
          };
          latte = {
            rosewater = "dc8a78";
            base = "eff1f5";
            text = "4c4f69";
            subtext0 = "6c6f85";
            subtext1 = "5c5f77";
            surface1 = "bcc0cc";
            surface2 = "acb0be";
            red = "d20f39";
            green = "40a02b";
            yellow = "df8e1d";
            blue = "1e66f5";
            pink = "ea76cb";
            teal = "179299";
          };
        };

        footColors = flavor: let
          p = palette.${flavor};
        in ''
          foreground=${p.text}
          background=${p.base}
          cursor=${p.base} ${p.rosewater}
          regular0=${p.surface1}
          regular1=${p.red}
          regular2=${p.green}
          regular3=${p.yellow}
          regular4=${p.blue}
          regular5=${p.pink}
          regular6=${p.teal}
          regular7=${p.subtext1}
          bright0=${p.surface2}
          bright1=${p.red}
          bright2=${p.green}
          bright3=${p.yellow}
          bright4=${p.blue}
          bright5=${p.pink}
          bright6=${p.teal}
          bright7=${p.subtext0}
        '';

        vscodeFlavor = flavor:
          if flavor == "frappe"
          then "Frappé"
          else capitalize flavor;

        #? One `case` arm per mode. Every per-mode value is resolved at build
        #? time, so the script body below is identical for dark and light.
        modeCase = mode: let
          flavor = aes.theme.${mode}.flavor;
          footSignal =
            if mode == "dark"
            then "USR1"
            else "USR2";
        in ''
          ${mode})
            kde_scheme=${aes.kdeScheme.${mode}}
            icon=${aes.icons.${mode}}
            gtk_theme=${variables."THEME_GTK_${toUpper mode}"}
            konsole_name=Catppuccin-${capitalize mode}
            vscode_theme='Catppuccin ${vscodeFlavor flavor}'
            foot_signal=${footSignal}
            ;;
        '';

        #? Answer to the old TODO: yes. As a writeShellApplication the tools come
        #? from `runtimeInputs` (no `${pkgs.x}/bin/x` plumbing), shellcheck runs at
        #? build time, and `theme-apply dark|light` works by hand too. Darkman's
        #? scripts become one-line wrappers, so there is one implementation
        #? instead of two near-identical mkScript outputs.
        themeApply = pkgs.writeShellApplication {
          name = "theme-apply";
          runtimeInputs = with pkgs; [
            dbus
            dconf
            gnugrep
            gnused
            procps
            systemd
            kdePackages.kconfig
            kdePackages.plasma-workspace
          ];
          #? Best-effort: one failing step (no Yakuake running, no Plasma) must
          #? not stop the rest, so no errexit/nounset/pipefail.
          bashOptions = [];
          #? SC2046: word-splitting the Yakuake terminal id list is intentional.
          excludeShellChecks = ["SC2046"];
          text = ''
            case "''${1:-}" in
            ${concatMapStringsSep "\n" modeCase modes}
              *)
                echo "usage: theme-apply dark|light" >&2
                exit 2
                ;;
            esac
            mode=$1

            #> Konsole / Yakuake: default profile for new tabs, setProfile for open ones
            kwriteconfig6 --file konsolerc --group "Desktop Entry" --key DefaultProfile "$konsole_name.profile"
            kwriteconfig6 --file yakuakerc --group "Desktop Entry" --key DefaultProfile "$konsole_name.profile"
            for terminal in $(busctl --user call org.kde.yakuake /yakuake/sessions org.kde.yakuake terminalIdList 2>/dev/null | sed 's/^s "//; s/"$//; s/,/ /g'); do
              busctl --user call org.kde.yakuake "/Sessions/$((terminal + 1))" org.kde.konsole.Session setProfile s "$konsole_name" >/dev/null 2>&1 || true
            done

            #> Plasma color scheme: only when a Plasma session is actually running
            if systemctl --user is-active --quiet plasma-plasmashell.service; then
              plasma-apply-colorscheme "$kde_scheme"
            fi

            #> Icons: --notify tells running apps (panel included) the value changed
            kwriteconfig6 --notify --file kdeglobals --group Icons --key Theme "$icon"
            for group in 0 1 2 3 4 5; do
              dbus-send --session --type=signal /KIconLoader org.kde.KIconLoader.iconChanged "int32:$group"
            done

            #> GTK / libadwaita / Electron (also what ghostty follows)
            base=/org/gnome/desktop/interface
            dconf write "$base/color-scheme" "'prefer-$mode'"
            dconf write "$base/gtk-theme" "'$gtk_theme'"
            dconf write "$base/icon-theme" "'$icon'"

            #> foot: USR1 forces the [colors-dark] section, USR2 [colors-light]
            pkill -"$foot_signal" -x foot || true

            #> ghostty follows color-scheme by itself via `theme = dark:...,light:...`.
            #> Only if it does not, uncomment (needs a ghostty that reloads on
            #> SIGUSR2; older ones exit on it, so test with nothing open first):
            # pkill -USR2 -x ghostty || true

            #> VS Code: push the theme into settings.json (Electron does not
            #> re-read the OS scheme reliably at runtime). sed instead of jq
            #> because settings.json is JSONC (comments, trailing commas).
            for dir in ".config/Code/User" ".config/Code - Insiders/User" ".config/VSCodium/User"; do
              settings="$HOME/$dir/settings.json"
              [ -f "$settings" ] || continue
              if grep -q '"workbench.colorTheme"' "$settings"; then
                sed -i -E "s|(\"workbench.colorTheme\"[[:space:]]*:[[:space:]]*)\"[^\"]*\"|\1\"$vscode_theme\"|" "$settings"
              else
                sed -i "0,/{/s|{|{\n  \"workbench.colorTheme\": \"$vscode_theme\",|" "$settings"
              fi
              sed -i -E 's|("window.autoDetectColorScheme"[[:space:]]*:[[:space:]]*)true|\1false|' "$settings"
            done

            #> Panel: deliberately NOT restarting plasmashell (slow). If the panel
            #> ever sticks on the old icons again, add:
            #>   systemctl --user try-restart plasma-plasmashell.service
          '';
        };
      in {
        home = {
          inherit stateVersion;
          username = user.name;
          homeDirectory = user.paths.home;
          #~@ Shell/dev tooling lives in the user's own profile, opted into
          #~@ via `shells`/`coding` in default.nix, rather than system-wide.
          packages = flatten (with packages; (
            forInterface
            ++ (map (app: pkgs.${app}) (user.apps or []))
            ++ (map (env: forShells.${env} or []) user.shells)
            ++ (map (dev: forCoding.${dev} or []) (user.coding or []))
            ++ [themeApply]
          ));
        };

        programs = {
          vicinae = let
            mkTheme = palette: {
              meta = {
                version = 1;
                inherit (palette) name description variant icon;
                inherits =
                  if palette.variant == "light"
                  then "vicinae-light"
                  else "vicinae-dark";
              };

              colors = with palette; {
                core = {
                  background = base;
                  foreground = text;
                  secondary_background = mantle;
                  border = surface1;
                  accent = blue; # TODO This should come from interface.${mode}.accent
                };
                accents = {
                  inherit blue green yellow;
                  magenta = pink;
                  orange = peach;
                  purple = mauve;
                  red = red;
                  cyan = teal;
                };
              };
            };
          in {
            enable = true;
            extensions = [];
            themes = listToAttrs (
              map (palette: {
                name = palette.slug;
                value = mkTheme palette;
              }) (attrValues palettes)
            );
          };
        };

        services.darkman = {
          enable = true;
          settings = with localization; {
            lat = latitude;
            lng = longitude;
          };
          darkModeScripts.theme = "${themeApply}/bin/theme-apply dark";
          lightModeScripts.theme = "${themeApply}/bin/theme-apply light";
        };

        #? Konsole profiles (one per mode) that theme-apply switches between.
        xdg.dataFile = listToAttrs (map (mode: let
            flavor = aes.theme.${mode}.flavor;
          in {
            name = "konsole/Catppuccin-${capitalize mode}.profile";
            value.text = ''
              [Appearance]
              ColorScheme=Catppuccin-${capitalize flavor}
              Font=Maple Mono NF,18

              [General]
              Name=Catppuccin-${capitalize mode}
              Parent=FALLBACK/

              [Interaction Options]
              AutoCopySelectedText=true
            '';
          })
          modes);

        #? foot needs explicit palettes; ghostty ships Catppuccin themes.
        #? If you already have these files (e.g. from your dots repo), merge
        #? the theme parts into them instead: home-manager refuses to clobber.
        xdg.configFile = {
          "foot/foot.ini".text = ''
            [colors-dark]
            ${footColors aes.theme.dark.flavor}
            [colors-light]
            ${footColors aes.theme.light.flavor}
          '';

          "ghostty/config".text = ''
            theme = dark:Catppuccin ${capitalize aes.theme.dark.flavor},light:Catppuccin ${capitalize aes.theme.light.flavor}
          '';
        };
      })
      users.normal;
  };
}
