{
  config,
  lib,
  pkgs,
  inputs ? null,
  system ? "x86_64-linux",
  ...
}: let
  inherit (lib.attrsets) attrNames filterAttrs getAttr listToAttrs mapAttrs optionalAttrs;
  inherit (lib.lists) flatten head intersectLists optional optionals;
  # inherit (lib.modules) mkIf;
  inherit (lib.strings) readFile toLower;
  inherit (pkgs) writeText writeShellApplication;
  inherit (pkgs.stdenv) hostPlatform;

  args = let
    src = import ./.;

    users = let
      normalize = principal: let
        home = "/home/${principal.name}";
        shells = principal.shells or ["bash"];
        role = principal.role or "normal";
        isNormalUser = role != "service";
      in
        principal
        // {
          inherit role shells isNormalUser;
          isSystemUser = !isNormalUser;
          paths =
            principal.paths or {
              inherit home;
              inherit (paths.roots) src;
              cfg = {
                source = "${paths.roots.src}/Configuration";
                target = "${home}/.config";
              };
            };
        }
        // optionalAttrs isNormalUser {
          defaultLocale = principal.defaultLocale or
          args.localization.defaultLocale;
          keyboard =
            principal.keyboard or {
              layout = "us";
              variant = "";
            };
        };

      normalized =
        mapAttrs
        (_: principal: normalize principal) (
          listToAttrs (
            map (value: {
              inherit value;
              inherit (value) name;
            })
            src.principals
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
        (_: principal: principal.isNormalUser)
        normalized;

      primary = enabled.${head (attrNames enabled)};

      core =
        mapAttrs
        (
          _: principal:
            {
              description = principal.description or principal.name;
              inherit (principal) isNormalUser isSystemUser;
              extraGroups =
                optionals
                (principal.role == "administrator") ["networkmanager" "wheel"];
              shell = getAttr (head principal.shells) pkgs;
            }
            // optionalAttrs (principal ? password) {inherit (principal) password;}
            // optionalAttrs (principal ? uid) {inherit (principal) uid;}
        )
        normalized;

      autoLogin = let
        candidates =
          filterAttrs
          (_: principal: principal.autoLogin or false)
          normalized;
      in {
        enable = candidates != {};
        user =
          if candidates == {}
          then primary.name
          else head (attrNames candidates);
      };
    in {inherit enabled disabled normal primary core autoLogin;};
  in
    src // {inherit users;};
  inherit (args) id name paths users stateVersion;
  inherit (args.localization) timeZone;

  sources = let
    revision = {
      nixpkgs = {
        url = "https://releases.nixos.org/nixos/unstable/nixos-26.11pre1077143.44a91898084f/nixexprs.tar.zst";
        sha256 = "sha256-uLLUj+TLUmBc6KrUzx76KZdPi5ZkI1ORR9A6lJUIZlo=";
      };
      home-manager = {
        url = "https://github.com/nix-community/home-manager/archive/a3dfb887d40d134af29fa8e924ba85a3e3a99194.tar.gz";
        sha256 = "sha256-wXAdaLBAjbQK/OfESV/i0pgolkz+Uo4SbBP/MbfGLHU=";
      };
      nix-index = {
        url = "https://github.com/nix-community/nix-index-database/archive/9ad722673ab3b3f91f02135e53775825b240b869.tar.gz";
        sha256 = "sha256-Dkg4VKPmDPqTwaiw2WH5br73tXoL1qrOO0xJnR4TlcA=";
      };
    };
    config' = {allowUnfree = true;};
  in {
    inherit revision;

    nixpkgs =
      if inputs ? nixpkgs
      then
        import inputs.nixpkgs {
          inherit system;
          config = config';
        }
      else
        import (fetchTarball revision.nixpkgs)
        {config = config';};

    home-manager = [
      (
        if inputs ? home-manager.nixosModules.home-manager
        then inputs.home-manager.nixosModules.home-manager
        else import "${fetchTarball revision.home-manager}/nixos"
      )
    ];

    dots =
      if inputs ? dots
      then inputs.dots
      else args.paths.roots.src;

    nix-index =
      optional (inputs ? nix-index.nixosModules.nix-index)
      inputs.nix-index.nixosModules.nix-index;
  };

  interface = let
    normalized = map toLower args.interface.desktops;

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
      intersectLists aliases.${desktop} normalized != [];
  in {
    inherit protocols;
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
    isWayland = protocols.wayland != [];
    isX11 = protocols.x11 != [];
    defaultSession = users.primary.desktop or "plasma";
  };

  shells = let
    priority = user.shells or ["bash"];
    normalized = map toLower priority;

    aliases = {
      bash = ["bash"];
      fish = ["fish"];
      nu = [
        "nu"
        "nushell"
      ];
      pwsh = [
        "pwsh"
        "powershell"
      ];
      zsh = [
        "zsh"
        "z-shell"
      ];
    };

    has = shell: intersectLists aliases.${shell} normalized != [];
  in {
    inherit priority;

    isBash = has "bash";
    isFish = has "fish";
    isNu = has "nu";
    isPwsh = has "pwsh";
    isZsh = has "zsh";
  };

  variables = let
    stems = {
      cfg = "/Configuration";
      host = "/${name}";
      hosts = "/API/nix/hosts";
    };
    DOTS_STORE = sources.dots;
    DOTS_LOCAL = user.paths.dots;
    DOTS_LOCAL_HOSTS = DOTS_LOCAL + stems.hosts;
    DOTS_STORE_HOSTS = DOTS_STORE + stems.hosts;
    DOTS = DOTS_LOCAL;
    DOTS_HOSTS = DOTS_LOCAL_HOSTS;
    DOTS_CONFIG = paths.roots.src;
    DOTS_STORE_CFG = DOTS_STORE + stems.cfg;
    DOTS_LOCAL_CFG = DOTS_LOCAL + stems.cfg;
    HOST = name;
  in {
    #~@ Dotfiles
    inherit
      DOTS
      DOTS_CONFIG
      DOTS_LOCAL
      DOTS_LOCAL_CFG
      DOTS_LOCAL_HOSTS
      DOTS_HOSTS
      DOTS_STORE
      DOTS_STORE_CFG
      DOTS_STORE_HOSTS
      HOST
      ;
    "DOTS_LOCAL_HOST_${HOST}" = DOTS_LOCAL_HOSTS + stems.host;
    "DOTS_STORE_HOST_${HOST}" = DOTS_STORE_HOSTS + stems.host;

    #~@ Inputs
    REV_URL_CORE = sources.revision.nixpkgs.url;
    REV_URL_HOME = sources.revision.home-manager.url;
    REV_URL_INDEX = sources.revision.nix-index.url;

    #~@ User Directories
    DOCUMENTS = "$HOME/Documents";
    DOWNLOADS = "$HOME/Downloads";
    MUSIC = "$HOME/Music";
    PICTURES = "$HOME/Pictures";
    PROJECTS = "$HOME/Projects";
    VIDEOS = "$HOME/Videos";
    WALLPAPERS = "$PICTURES/Wallpapers";
    WALLPAPER_DIRS = [
      "$WALLPAPERS"
      "$HOME/.local/share/wallpapers"
      "$HOME/.local/share/backgrounds"
      "/usr/share/pixmaps"
      "/usr/share/backgrounds"
      "/usr/local/share/wallpapers"
    ];
  };

  packages = let
    #~@ Languages & Development
    dev = let
      Markup = with pkgs;
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

      Nix = with pkgs; [
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
        nvfetcher
        nixfmt
        statix
      ];

      Nushell = optionals shells.isNu (
        with pkgs;
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
          ])
      );

      PowerShell = optionals shells.isPwsh (
        with pkgs; [
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
        ]
      );

      Python = with pkgs; [
        python3Minimal
        ruff
      ];

      Rust = with pkgs; [
        cargo
        rustc
        clippy
        rustfmt
        rust-analyzer
        leptosfmt
      ];

      ShellScript = with pkgs; [
        shellcheck
        shfmt

        (writeShellApplication {
          name = "shlint";
          runtimeInputs = [shellcheck shfmt];
          text = ''
            for file in "$@"; do
              shellcheck "$file"
              shfmt -w -s "$file"
            done
          '';
        })
      ];

      Zig = with pkgs; [
        zig
        ziglint
        zls
      ];
    in
      flatten [
        Markup
        Nix
        Nushell
        PowerShell
        Python
        Rust
        ShellScript
        Zig
      ];

    files = with pkgs; [
      dua
      dust
      eza
      fd
      file
      fzf
      lsd
      ouch
      p7zip
      rsync
      sad
      trashy
      udiskie
    ];

    network = with pkgs; [
      curl
      gh
      gitui
      speedtest-go
      wget
    ];

    media = with pkgs; [
      # nomacs
      brave
      brave-search-cli
      freetube
      imagemagick
      imv
      kitty
      mpv
      qimgv
      shortwave
      viu
      vscode-fhs
    ];

    theme = [
      (writeShellApplication {
        name = "theme-toggle";
        runtimeInputs = with pkgs; [coreutils libnotify];
        bashOptions = []; #? the script probes tools that may legitimately fail
        text = ''
          # Use the DMS-generated Matugen schemes only while DMS is running;
          # otherwise (plain Plasma session) fall back to Breeze.
          if command -v dms >/dev/null 2>&1 && dms ipc call theme getMode >/dev/null 2>&1; then
            THEME_KDE_SCHEME_LIGHT=DankMatugenLight
            THEME_KDE_SCHEME_DARK=DankMatugenDark
            export THEME_KDE_SCHEME_LIGHT THEME_KDE_SCHEME_DARK
          fi

          ${readFile (
            sources.dots
            + "/Libraries/posix/interface/theme/theme-switch.sh"
          )}
        '';
      })
    ];

    #~@ Platform Helpers
    wayland = optionals interface.isWayland (
      with pkgs;
        [
          wl-clipboard
          xwayland-satellite
        ]
        ++ optional interface.isNiri alacritty
    );

    linux = optionals hostPlatform.isLinux (
      with pkgs; [
        bubblewrap
        xsel
      ]
    );

    darwin = optionals hostPlatform.isDarwin (with pkgs; [
      pngpaste
    ]);

    plasma = optionals interface.isPlasma (
      (with pkgs; [vscode-runner])
      ++ (with pkgs.kdePackages; [
        kate
        kio
        yakuake
      ])
    );

    #~@ System & Utilities
    utils = with pkgs; [
      (writeShellApplication {
        name = "nixos-switch";
        runtimeInputs = with pkgs; [coreutils git gum nixos-rebuild];
        text = ''
          export DOTS="${variables.DOTS}"
          export DOTS_CONFIG="${variables.DOTS_CONFIG}"
          export DOTS_HOSTS="${variables.DOTS_HOSTS}"
          export HOST="${variables.HOST}"
          export REV_URL_CORE="${variables.REV_URL_CORE}"
          export REV_URL_HOME="${variables.REV_URL_HOME}"
          export REV_URL_INDEX="${variables.REV_URL_INDEX}"
          ${readFile (
            sources.dots
            + "/Libraries/posix/packages/manager/nix/nixos-switch.sh"
          )}
        '';
      })

      bat
      gitui
      treefmt
      gum
      helix
      jq
      jql
      patch
      ripgrep
      pkg-config
      gcc
      btop
      coreutils
      diffutils
      fastfetch
      fend
      figlet
      findutils
      gawk
      getent
      gnome-randr
      gnused
      lolcat
      lshw
      pciutils
      procs
      usbutils
      uutils-coreutils-noprefix
      wlr-randr
      vicinae
    ];
  in
    flatten (
      linux
      ++ darwin
      ++ wayland
      ++ plasma
      ++ dev
      ++ utils
      ++ network
      ++ files
      ++ media
      ++ theme
    );
in {
  boot = let
    loader =
      args.boot.loader or {
        system = "systemd-boot";
        device = "";
        timeout = 1;
      };
  in {
    loader = {
      grub = {
        inherit (loader) device;
        enable = loader.system == "grub";
        useOSProber = true;
        fsIdentifier = "provided";
      };
      inherit (loader) timeout;
    };

    kernelPackages =
      pkgs.${
        args.packages.kernel or "linuxPackages_latest"
      };
  };

  console = {
    keyMap = args.user.keyboard.layout;
  };

  environment = {
    sessionVariables = variables;
    systemPackages = packages;
    plasma6.excludePackages = with pkgs.kdePackages; [
      elisa
      gwenview
    ];
  };

  i18n = {
    inherit (user) defaultLocale;
  };

  imports =
    [./hardware-configuration.nix]
    ++ sources.home-manager
    ++ sources.nix-index;

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
  };

  nixpkgs = {
    pkgs = sources.nixpkgs;
  };

  programs =
    {
      bash = {
        enable = true;
        blesh = {
          enable = true;
        };
        undistractMe = {
          enable = true;
        };
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

      bandwhich = {
        enable = true;
      };

      cpu-energy-meter = {
        enable = true;
      };

      direnv = {
        enable = true;
        silent = true;
        angrr = {
          enable = true;
        };
      };

      dms-shell = {
        enable = true;
      };

      firefox = {
        enable = true;
      };

      fish = {
        enable = shells.isFish;
      };

      foot = {
        enable = interface.isWayland;
        xdg.serverAutostart = true;

        settings = {
          main = {
            selection-target = "clipboard";
            font = "Monospace:size=18";
          };

          scrollback = {
            lines = 1000000;
          };
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
          user = {
            inherit (users.primary) email name;
          };
          init = {
            defaultBranch = "main";
          };
          safe.directory = [
            paths.dots
          ];
          url = {
            "https://github.com/" = {
              insteadOf = [
                "gh:"
                "github:"
              ];
            };
          };
        };
      };

      hyprland = {
        enable = interface.isHyprland;
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
      };

      mango = {
        enable = interface.isMango;
      };

      nh = {
        enable = true;
        clean.enable = true;
        clean.extraArgs = "--keep-since 4d --keep 3";
      };

      niri = {
        enable = interface.isNiri;
      };

      nix-index = {
        enable = true;
      };

      nix-ld = {
        enable = true;
      };

      starship = {
        enable = true;
        transientPrompt.enable = true;
      };

      zsh = {
        enable = shells.isZsh;
      };
    }
    // optionalAttrs (sources.nix-index != []) {
      nix-index-database.comma.enable = true;
    };

  security = {
    sudo.extraRules = [
      {
        users = [users.primary.name];
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
      defaultSession = lib.mkForce (
        if interface.isPlasma
        then "plasma"
        else if interface.isNiri
        then "niri"
        else interface.defaultSession
      );

      autoLogin = {
        user = user.name;
        enable = autoLogin;
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
        inherit (user.keyboard) layout variant;
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

  system = let
    inherit (user) name;
    inherit (user.paths.cfg) target source;
  in {
    inherit stateVersion;
    activationScripts = {
      biome = let
        default = writeText "biome.jsonc" ''
          {
            "assist": {
              "enabled": true,
              "actions": {
                "source": {
                  "useSortedKeys": "on"
                }
              }
            },
            "linter": {
              "enabled": true,
              "rules": {
                "recommended": true
              }
            },
            "formatter": {
              "lineWidth": 80,
              "indentStyle": "space",
              "indentWidth": 6
            }
          }
        '';

        defined = source + "/biome/config.jsonc";
        deploy_path = "/.biome.jsonc";
      in {
        text = ''
          CFG_BIOME="${default}"
          [ -f "${defined}" ] && CFG_BIOME="${defined}"

          install -m 0644 "$CFG_BIOME" "${deploy_path}"
          install -o ${name} -g users -m 0644 \
            "$CFG_BIOME" "${user.paths.home + deploy_path}"
        '';
      };

      helix = let
        default = {
          conf = writeText "helix-config.toml" ''
            theme = "base16_transparent"

            [editor]
              auto-format = true
              cursorline = true
              true-color = true

              [editor.cursor-shape]
                insert = "bar"
                normal = "block"
                select = "underline"

              [editor.lsp]
                display-messages = true
                display-inlay-hints = true


            [keys]
              [keys.insert]
                A-e = "normal_mode"
                A-f = ["normal_mode", ":format"]
                A-q = ["normal_mode", ":quit"]
                A-space = "normal_mode"
                A-w = ["normal_mode", ":write"]

              [keys.normal]
                A-e = ["collapse_selection", "keep_primary_selection"]
                A-w = ["collapse_selection", "keep_primary_selection", ":write"]
                A-q = ":quit"
                ret = ["open_below", "normal_mode"]

              [keys.select]
                A-e = ["collapse_selection", "keep_primary_selection", "normal_mode"]
                A-q = ["normal_mode", ":quit"]
                A-w = ["collapse_selection", "keep_primary_selection", "normal_mode", ":write"]

          '';

          lang = writeText "helix-languages.toml" ''
            [[language]]
            name = "nix"
            language-servers = ["nixd"]
            formatter = { command = "alejandra" }
            auto-format = true
          '';
        };

        defined = let
          base = source + "/helix";
        in {
          conf = base + "/config.toml";
          lang = base + "/languages.toml";
        };

        deploy = let
          files = {
            conf = "config.toml";
            lang = "languages.toml";
          };

          install = {
            base,
            owner,
            group,
          }: ''
            install -d -o ${owner} -g ${group} "${base}"
            install -o ${owner} -g ${group} "$_conf" "${base}/${files.conf}"
            install -o ${owner} -g ${group} "$_lang" "${base}/${files.lang}"
          '';
        in {
          inherit files install;

          user = {
            base = target + "/helix";
            owner = name;
            group = "users";
          };

          root = {
            base = "/root/.config/helix";
            owner = "root";
            group = "root";
          };
        };
      in {
        text = ''
          _conf="${default.conf}"
          [ -f "${defined.conf}" ] && _conf="${defined.conf}"

          _lang="${default.lang}"
          [ -f "${defined.lang}" ] && _lang="${defined.lang}"

          ${deploy.install deploy.root}
          ${deploy.install deploy.user}
        '';
      };

      hypridle = let
        cfg = writeText "hypridle.conf" ''
          general {
            lock_cmd = pidof hyprlock || hyprlock
            before_sleep_cmd = loginctl lock-session
            after_sleep_cmd = hyprctl dispatch dpms on
          }

          listener {
            timeout = 300
            on-timeout = hyprlock
          }

          # listener {
          #   timeout = 330
          #   on-timeout = hyprctl dispatch dpms off
          #   on-resume = hyprctl dispatch dpms on
          # }
        '';
      in {
        text = ''
          install -d -o ${name} -g users ${target}/hypr
          install -o ${name} -g users ${cfg} ${target}/hypr/hypridle.conf
        '';
      };
      treefmt = let
        default = writeText "treefmt.toml" ''
          [formatter.alejandra]
          command = "alejandra"
          includes = ["*.nix"]
        '';
        defined = "${source}/treefmt/config.toml";
        deploy_path = "/.treefmt.toml";
      in {
        text = ''
          CFG_TREEFMT=${default}
          [ -f ${defined} ] && CFG_TREEFMT=${defined}
          export CFG_TREEFMT
          install -m 0644 $CFG_TREEFMT ${deploy_path}
          install -o ${name} -g users -m 0644 \
            "$CFG_TREEFMT" "${user.paths.home + deploy_path}"
        '';
      };
    };
  };

  time = {
    inherit timeZone;
  };

  users.users = users.nixos;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = args;
    users =
      mapAttrs (_: principal: {
        home = {
          inherit stateVersion;
          username = principal.name;
          homeDirectory = principal.paths.home;
        };
      })
      users.normal;
  };
}
