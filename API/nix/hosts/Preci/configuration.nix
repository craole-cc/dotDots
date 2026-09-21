{
  config,
  lib,
  pkgs,
  inputs ? null,
  system ? "x86_64-linux",
  ...
}: let
  inherit (lib.lists) flatten intersectLists optionals;
  inherit (lib.strings) readFile toLower;
  inherit (pkgs) writeText writeShellApplication;
  inherit (pkgs.stdenv) hostPlatform;

  pkgConfig = {
    allowUnfree = true;
  };

  sources = {
    nixpkgs =
      if inputs != null && inputs ? nixpkgs
      then
        import inputs.nixpkgs {
          inherit system;
          config = pkgConfig;
        }
      else
        import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz") {
          config = pkgConfig;
        };

    home-manager =
      if inputs != null && inputs ? home-manager
      then inputs.home-manager
      else fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz";

    dots =
      if inputs != null && inputs ? dots
      then inputs.dots
      else user.paths.dots;
  };

  name = "Preci";
  id = "91ba73c7";
  timeZone = "America/Jamaica";
  autoLogin = true;
  stateVersion = "26.05";
  paths.roots.src = "/etc/nixos";

  user = {
    name = "craole-cc";
    email = "134658831+craole-cc@users.noreply.github.com";
    description = "Craig 'Craole' Cole";
    defaultLocale = "en_GB.UTF-8";
    keyboard = {
      layout = "us";
      variant = "";
    };
    paths = let
      home = "/home/${user.name}";
      pictures = home + "/Pictures";
      wallpapers = pictures + "/Wallpapers";
      projects = home + "/Projects";
      dots = projects + "/dotDots";
      cfg = {
        target = home + "/.config";
        source = dots + "/Configuration";
      };
    in {
      inherit
        home
        dots
        pictures
        projects
        cfg
        wallpapers
        ;
    };
    panels = [];
    launchers = ["vicinae"];
    shells = [
      "bash"
      "nushell"
      "powershell"
      "zsh"
    ];
  };

  interface = let
    desktops = [
      "plasma"
      # "hyprland"
      "niri"
      # "mango"
      # "cosmic"
    ];

    normalized = map toLower desktops;

    aliases = {
      plasma = [
        "plasma"
        "plasma6"
        "kde"
      ];
      hyprland = ["hyprland"];
      niri = ["niri"];
      gnome = ["gnome"];
      cosmic = ["cosmic"];
      i3 = ["i3"];
      bspwm = ["bspwm"];
      openbox = ["openbox"];
      lab = [
        "labwc"
        "lab"
      ];
      mango = [
        "mango"
        "mangowc"
      ];
    };

    has = desktop: intersectLists aliases.${desktop} normalized != [];

    protocols = {
      wayland = intersectLists normalized [
        "cosmic"
        "gnome"
        "hyprland"
        "kde"
        "mangowc"
        "niri"
        "plasma"
        "plasma6"
      ];

      x11 = intersectLists normalized [
        "bspwm"
        "i3"
        "labwc"
        "openbox"
      ];
    };

    launchers = user.launchers or ["vicinae"];
    panels = user.panels or [];
  in {
    inherit
      desktops
      launchers
      panels
      protocols
      ;

    isBspwm = has "bspwm";
    isCosmic = has "cosmic";
    isGnome = has "gnome";
    isHyprland = has "hyprland";
    isI3 = has "i3";
    isLab = has "lab";
    isMango = has "mango";
    isNiri = has "niri";
    isOpenbox = has "openbox";
    isPlasma = has "plasma";
    isWayland = protocols.wayland != [];
    isX11 = protocols.x11 != [];

    defaultSession = "plasma";
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
        ++ (with typstPackages; [
          typsy
        ]);

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
      wget
      gh
      gitui
      speedtest-go
    ];

    media = with pkgs; [
      shortwave
      imagemagick
      imv
      nomacs
      qimgv
      viu
      kitty
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
            export THEME_KDE_SCHEME_LIGHT=DankMatugenLight
            export THEME_KDE_SCHEME_DARK=DankMatugenDark
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
      with pkgs; [
        wl-clipboard
        xwayland-satellite
      ]
    );

    linux = optionals hostPlatform.isLinux (
      with pkgs; [
        bubblewrap
        xsel
      ]
    );

    darwin = optionals hostPlatform.isDarwin (with pkgs; [pngpaste]);

    plasma = optionals interface.isPlasma (
      (with pkgs; [vscode-runner])
      ++ (with pkgs.kdePackages; [
        kate
        yakuake
      ])
    );

    #~@ System & Utilities
    utils = with pkgs; [
      (writeShellApplication {
        name = "switch";
        runtimeInputs = with pkgs; [coreutils git gum nixos-rebuild];
        text = ''
          #~@ Configure
          source="''${PRJ_DOTS}/API/nix/hosts/${name}"
          target="/etc/nixos"
          mode="config"
          message=""

          #~@ Parse
          while [ $# -gt 0 ]; do
            case "''${1:-}" in
              --flake) mode="flake" ;;
              --legacy | --config) mode="config" ;;
              --message|--msg|-m)
                if [ -n "''${2:-}" ]; then
                  message="$2"
                  shift
                else
                  gum log --level error "$1 requires a value"
                  exit 1
                fi
                ;;
              *)
                if [ -z "$message" ]; then
                  message="$1"
                else
                  message="$message $1"
                fi
                ;;
            esac
            shift
          done


          #~@ Commit
          if [ -d "$source/.git" ]; then
            if [ -z "$message" ]; then
              message="$(git -C "$source" log -1 --pretty=%s 2>/dev/null || true)"
              [ -z "$message" ] && message="update"
            fi

            git -C "$source" add --all

            if ! git -C "$source" diff --cached --quiet; then
              gum log \
                --level info \
                --structured "Committing changes" \
                source "$source" \
                message "$message"

              git -C "$source" commit --message "$message"
            fi
          fi

          #~@ Deploy
          if [ -d "$source" ]; then
            gum log \
              --level info \
              --structured "Syncing config" \
              source "$source" \
              target "$target"
            sudo cp "$source"/* "$target"
          else
            gum log \
              --level warn \
              --structured "Source not found — building with existing target" \
              source "$source" \
              target "$target"
          fi

          #~@ Switch
          case "$mode" in
            flake) sudo nixos-rebuild switch --flake;;
            config) sudo nixos-rebuild switch --no-flake ;;
            *) ;;
          esac
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

  variables = {
    PRJ_DOTS = user.paths.dots;
    DOTS = paths.roots.src;
    DOTS_CFG = user.paths.cfg.source;
  };
in {
  boot = {
    loader = {
      grub = {
        enable = true;
        device = "/dev/sda";
        useOSProber = true;
        fsIdentifier = "provided";
      };
      timeout = 1;
    };

    kernelPackages = pkgs.linuxPackages_latest;
  };

  console = {
    keyMap = user.keyboard.layout;
  };

  environment = {
    sessionVariables = variables;
    systemPackages = packages;
  };

  i18n = {
    inherit (user) defaultLocale;
  };

  imports = [
    ./hardware-configuration.nix
    "${sources.home-manager}/nixos"
  ];

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

  programs = {
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

    chromium = {
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
      enable = with interface; isHyprland || isNiri;
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
          inherit (user) email name;
        };
        init = {
          defaultBranch = "main";
        };
        safe = {
          directory = "/etc/nixos";
        };
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
  };

  security = {
    sudo.extraRules = [
      {
        users = [user.name];
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
        deploy = "/biome.jsonc";
      in {
        text = ''
          _cfg="${default}"
          [ -f "${defined}" ] && _cfg="${defined}"

          install -m 0644 "$_cfg" "${deploy}"
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
        deploy_path = "/treefmt.toml";
      in {
        text = ''
          CFG_TREEFMT=${default}
          [ -f ${defined} ] && CFG_TREEFMT=${defined}
          export CFG_TREEFMT
          install -m 0644 $CFG_TREEFMT ${deploy_path}
        '';
      };
    };
  };

  time = {
    inherit timeZone;
  };

  users = {
    users.${user.name} = {
      isNormalUser = true;
      inherit (user) description;
      extraGroups = ["networkmanager" "wheel"];
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${user.name} = {
      home.stateVersion = stateVersion;
    };
  };
}
