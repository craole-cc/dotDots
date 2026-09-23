{
  config,
  lib,
  pkgs,
  inputs ? null,
  system ? "x86_64-linux",
  ...
}: let
  inherit (lib.attrsets) attrNames filterAttrs getAttr isAttrs listToAttrs mapAttrs optionalAttrs recursiveUpdate;
  inherit (lib.lists) flatten head intersectLists isList optional optionals;
  inherit (lib.modules) mkForce;
  inherit (lib.strings) isString readFile stringLength toLower trim;
  inherit (pkgs) writeShellApplication;
  inherit (pkgs.stdenv) hostPlatform;

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
              recursiveUpdate {
                layout = "us";
                variant = "";
              }
              principal.keyboard;
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
          enable = isNotEmpty candidates;
        in {
          inherit enable;
          user =
            if enable
            then head (attrNames candidates)
            else primary.name;
        };
      in {inherit enabled disabled normal primary core autoLogin;};

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
    };
  inherit (args) id localization name paths stateVersion users;

  sources = let
    normalize = {
      owner,
      repo,
      rev,
      sha256,
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
    }:
      if inputs ? ${name}
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
        rev = "44a91898084f3e69bbbf407aa7e8d64efd6e812b";
        sha256 = "sha256-uLLUj+TLUmBc6KrUzx76KZdPi5ZkI1ORR9A6lJUIZlo=";
      };

      home-manager = normalize {
        owner = "nix-community";
        repo = "home-manager";
        rev = "a3dfb887d40d134af29fa8e924ba85a3e3a99194";
        sha256 = "sha256-wXAdaLBAjbQK/OfESV/i0pgolkz+Uo4SbBP/MbfGLHU=";
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
      else import (fetchSrc revision.nixpkgs) {config = config';};

    home-manager = [
      (fetchMod {
        name = "home-manager";
        path = "nixos";
      })
    ];

    dots =
      if inputs ? dots
      then inputs.dots
      else fetchSrc revision.dots;

    catppuccin = fetchMod {
      name = "catppuccin";
      path = "modules/nixos";
    };

    nix-index = fetchMod {
      name = "nix-index";
      default = src: (import src).nixosModules.nix-index;
    };
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
      isNotEmpty
      (intersectLists aliases.${desktop} normalized);
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
    isWayland = isNotEmpty protocols.wayland;
    isX11 = isNotEmpty protocols.x11;
    defaultSession = users.primary.desktop or "plasma";
  };

  variables = let
    stems = {
      cfg = "/Configuration";
      host = "/${name}";
      hosts = "/API/nix/hosts";
    };
    env = variables;
  in {
    #~@ Paths
    DOTS_STORE = sources.dots;
    DOTS_LOCAL = paths.roots.src;
    DOTS_BUILD = paths.roots.run;
    DOTS = env.DOTS_LOCAL;
    DOTS_HOSTS = env.DOTS_LOCAL_HOSTS;
    DOTS_LOCAL_HOSTS = env.DOTS_LOCAL + stems.hosts;
    DOTS_STORE_HOSTS = env.DOTS_STORE + stems.hosts;
    "DOTS_LOCAL_HOST_${env.HOST}" = env.DOTS_LOCAL_HOSTS + stems.host;
    "DOTS_STORE_HOST_${env.HOST}" = env.DOTS_STORE_HOSTS + stems.host;
    DOTS_STORE_CFG = env.DOTS_STORE + stems.cfg;
    DOTS_LOCAL_CFG = env.DOTS_LOCAL + stems.cfg;

    #~@ Inputs
    REV_URL_CORE = sources.revision.nixpkgs.url;
    REV_URL_HOME = sources.revision.home-manager.url;
    REV_URL_INDEX = sources.revision.nix-index.url;

    #~@ Metadata
    HOST = name;

    #~@ Theme
    THEME_KDE_LIGHT = "BreezeLight";
    THEME_KDE_DARK = "BreezeDark";
    THEME_GTK_LIGHT = "catppuccin-latte-blue-standard";
    THEME_GTK_DARK = "catppuccin-frappe-blue-standard";
    THEME_ICONS_LIGHT = "buuf-nestort";
    THEME_ICONS_DARK = "candy-icons";
  };

  packages = flatten (
    with pkgs;
      [
        (writeShellApplication {
          name = "nixos-switch";
          runtimeInputs = with pkgs; [coreutils git gum nixos-rebuild];
          text = ''
            export DOTS="${variables.DOTS}"
            export DOTS_BUILD="${variables.DOTS_BUILD}"
            export DOTS_HOSTS="${variables.DOTS_HOSTS}"
            export HOST="${variables.HOST}"
            export REV_URL_CORE="${variables.REV_URL_CORE}"
            export REV_URL_HOME="${variables.REV_URL_HOME}"
            export REV_URL_INDEX="${variables.REV_URL_INDEX}"
            ${readFile (sources.dots + "/Libraries/posix/packages/manager/nix/nixos-switch.sh")}
          '';
        })

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
        alejandra
        bat
        btop
        cachix
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
        gcc
        getent
        gh
        gitui
        gnused
        gum
        helix
        imagemagick
        imv
        jq
        jql
        lolcat
        lorri
        lsd
        lshw
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
        ouch
        p7zip
        patch
        pciutils
        pkg-config
        procs
        ripgrep
        rsync
        sad
        shellcheck
        shfmt
        speedtest-go
        statix
        trashy
        treefmt
        udiskie
        usbutils
        uutils-coreutils-noprefix
        viu
        wget
        wlr-randr
        yazi
      ]
      ++ optionals interface.isWayland (with pkgs; [
        wl-clipboard
        xwayland-satellite
        foot
      ])
      ++ optionals hostPlatform.isLinux (with pkgs; [bubblewrap xsel])
      ++ optionals hostPlatform.isDarwin (with pkgs; [pngpaste])
      ++ optional interface.isNiri (with pkgs; [alacritty])
      ++ optional interface.isHyprland (with pkgs; [kitty])
      ++ optionals interface.isPlasma (with pkgs.kdePackages; [
        kate
        kio
        yakuake
      ])
      ++ optionals (with interface; isX11 || isWayland) (with pkgs; [
        brave
        freetube
        imagemagick
        imv
        qbittorrent-enhanced
        qimgv
        shortwave
        viu
        vscode-fhs
      ])
  );
in {
  imports =
    [./hardware-configuration.nix]
    ++ sources.home-manager
    ++ sources.nix-index;

  boot = let
    loader =
      recursiveUpdate {
        manager = "systemd-boot";
        device = "nodev";
        timeout = 1;
      }
      args.boot.loader;
  in {
    loader = {
      grub = {
        inherit (loader) device;
        enable = loader.manager == "grub";
        useOSProber = true;
        fsIdentifier = "provided";
        gfxmodeEfi = "1920x1080";
        font = "${
          pkgs.nerd-fonts.jetbrains-mono
        }/share/fonts/truetype/NerdFonts/JetBrainsMonoNerdFont-Regular.ttf";
      };
      systemd-boot = {
        enable = loader.manager == "systemd-boot";
        consoleMode = "max";
      };
      inherit (loader) timeout;
    };

    kernelPackages =
      pkgs.${
        args.packages.kernel or "linuxPackages_latest"
      };
  };

  catppuccin = {
    enable = true;
    flavor = "frappe";
  };

  console = {
    keyMap = args.user.keyboard.layout;
  };

  environment = {
    sessionVariables = variables;
    systemPackages = packages;
    plasma6.excludePackages = with pkgs.kdePackages; [
      khelpcenter
      # elisa
      # gwenview
    ];
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
    inherit (users.primary) defaultLocale;
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
        user = {inherit (users.primary) email name;};
        init.defaultBranch = "main";
        safe.directory = [paths.dots];
        url."https://github.com/".insteadOf = ["gh:" "github:"];
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

  qt = {
    enable = true;
    platformTheme = "gnome";
    style.name = "adwaita";
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
    darkman = {
      enable = true;
      settings = {
        lat = localization.latitude;
        lng = localization.longitude;
      };
    };

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
        inherit (users.primary.keyboard) layout variant;
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
