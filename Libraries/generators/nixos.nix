{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) attrValues attrNames attrByPath filterAttrs genAttrs mapAttrs mapAttrsToList;
  inherit (lib.lists) filter concatLists elem head length optional unique;
  inherit (lib.modules) mkDefault mkIf;
  inherit (_.generators.firefox) zenVariant;
  inherit (_.attrsets.resolution) getPackage;
  inherit (_) hostFunctionalities userCapabilities;

  mkAdmin = name: {
    #> Apply this rule only to the named user.
    users = [name];

    #> Allow that user to run any command as any user/group, without password.
    #? Equivalent to: name ALL=(ALL:ALL) NOPASSWD: ALL
    commands = [
      {
        command = "ALL";
        options = ["SETENV" "NOPASSWD"];
      }
    ];
  };

  isAdmin = u: elem (u.role or null) ["admin" "administrator"];

  mkHosts = {
    inputs,
    hosts,
    users,
    args,
  }:
    mapAttrs
    (
      name: host: let
        system = host.platform or builtins.currentSystem;
        hostUsers = attrValues (attrNames host.users or {});
        adminsUsersRaw = filterAttrs (_: isAdmin) host.users;
        adminUsers =
          if adminsUsersRaw != {}
          then adminsUsersRaw
          else if length hostUsers == 1
          then let
            onlyName = head hostUsers;
          in {
            ${onlyName} = users.${onlyName};
          }
          else adminsUsersRaw;
        hasAudio = elem "audio" (host.functionalities or []);
      in
        inputs.nixosCore.lib.nixosSystem {
          inherit system;
          specialArgs = args;
          modules =
            [
              (with host;
                {pkgs, ...}: {
                  # Policy check:
                  # - If multiple users exist, at least one must be an administrator.
                  # - A single-user host may omit role and will be auto-promoted to admin.
                  assertions = [
                    {
                      assertion = (adminUsers != {}) || (length hostUsers <= 1);
                      message = ''
                        When multiple users are defined for a host, at least one must have role = "administrator".
                      '';
                    }
                  ];

                  inherit imports;

                  system = {
                    inherit stateVersion;
                  };

                  nix = {
                    # gc = {
                    #   automatic = true;
                    #   persistent = true;
                    #   dates = "weekly";
                    #   options = "--delete-older-than 5d";
                    # };

                    # optimise = {
                    #   automatic = true;
                    #   persistent = true;
                    #   dates = "weekly";
                    # };

                    settings = {
                      # auto-optimise-store = true;
                      experimental-features = [
                        "nix-command"
                        "flakes"
                        "pipe-operators"
                      ];
                      max-jobs = specs.cpu.cores or "auto";
                      # substituters = ["https://cache.nixos.org/"];
                      # trusted-substituters = [
                      #   "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                      #   "https://hydra.nixos.org/"
                      # ];
                      trusted-users = [
                        "root"
                        "@wheel"
                      ];
                    };

                    # extraOptions = ''
                    #   download-buffer-size = 524288000
                    # '';
                  };

                  nixpkgs = {
                    hostPlatform = system;
                    config.allowUnfree = packages.allowUnfree or false;
                  };

                  boot = {
                    kernelPackages = mkIf ((packages.kernel or null) != null) pkgs.${packages.kernel};
                    loader = {
                      systemd-boot.enable = interface.bootLoader or null == "systemd-boot";
                      efi.canTouchEfiVariables = true; # TODO: Make this dynamic
                      timeout = interface.bootLoaderTimeout or 1;
                    };
                  };

                  fileSystems = let
                    mkFileSystem = _: fs: let
                      base = {
                        device = fs.device;
                        fsType = fs.fsType;
                      };
                      opts = fs.options or [];
                    in
                      #> Combine base attributes with options if they exist.
                      if opts == []
                      then base
                      else base // {options = opts;};
                  in
                    mapAttrs mkFileSystem (devices.file or {});

                  swapDevices = let
                    mkSwapDevice = s: {device = s.device;};
                  in
                    map mkSwapDevice (devices.swap or []);

                  networking = {
                    #> System name
                    hostName = name;

                    #> 32-bit host ID (ZFS requirement)
                    hostId = host.id or null;

                    #> Enable NetworkManager if interfaces are defined
                    networkmanager.enable = devices.network != [];

                    #> DNS Nameservers from host config
                    inherit (access) nameservers;

                    #> Generate interface configurations
                    interfaces = let
                      mkNetworkInterface = _: {useDHCP = mkDefault true;};
                    in
                      genAttrs (devices.network or []) mkNetworkInterface;

                    #> Configure firewall
                    firewall = let
                      inherit (access.firewall) tcp udp;
                      enable = access.firewall.enable or false;
                    in {
                      inherit enable;

                      #~@ TCP Configuration
                      allowedTCPPorts = tcp.ports;
                      allowedTCPPortRanges = tcp.ranges;

                      #~@ UDP Configuration
                      allowedUDPPorts = udp.ports;
                      allowedUDPPortRanges = udp.ranges;
                    };
                  };

                  time = {
                    timeZone = localization.timeZone or null;
                    hardwareClockInLocalTime = elem "dualboot-windows" functionalities;
                  };

                  location = {
                    latitude = localization.latitude or null;
                    longitude = localization.longitude or null;
                    provider = localization.locator or "geoclue2";
                  };

                  i18n = {
                    defaultLocale = localization.defaultLocale or null;
                  };

                  services = {
                    pipewire = mkIf hasAudio {
                      enable = true;
                      alsa.enable = true;
                      alsa.support32Bit = true;
                      pulse.enable = true;
                      jack.enable = true;
                      wireplumber.enable = true;
                    };

                    pulseaudio.enable = false;
                  };

                  security = {
                    rtkit.enable = hasAudio;
                    sudo = {
                      #> Restrict sudo to members of the wheel group (root is always allowed).
                      execWheelOnly = true;

                      #> For each admin user, grant passwordless sudo for all commands.
                      extraRules = mapAttrsToList (name: _: mkAdmin name) adminUsers;
                    };
                  };

                  environment = let
                    dots = host.paths.dots or null;
                  in {
                    shellAliases = {
                      edit-dots = "$EDITOR ${dots}";
                      ide-dots = "$VISUAL ${dots}";
                      push-dots = "gitui --directory ${dots}";
                      flake-dots = "sudo nixos-rebuild switch --flake ${dots}";
                      switch = "push-dots; flake-dots";
                      ll = "lsd --long --git --almost-all";
                      lt = "lsd --tree";
                      lr = "lsd --long --git --recursive";
                    };
                    sessionVariables =
                      if dots != null
                      then {DOTS = dots;}
                      else {};
                    systemPackages = with pkgs; [
                      #~@ Development
                      helix
                      nil
                      nixd
                      nixfmt
                      alejandra
                      rust-script
                      rustfmt
                      gcc

                      #~@ Tools
                      gitui
                      lm_sensors
                      toybox
                      lshw
                      lsd
                      mesa-demos
                      cowsay
                    ];
                  };
                })
            ]
            ++ [
              inputs.nixosHome.nixosModules.home-manager
              (mkUsers {inherit host users system inputs args;})
            ]
            ++ [];
        }
    )
    hosts;

  mkUsers = {
    users,
    host,
    system,
    inputs,
    args,
  }: {
    config,
    pkgs,
    ...
  }: let
    inherit (host) stateVersion interface;

    #> Merge user config from API/users/ with host-specific settings
    mergedUsers =
      mapAttrs (
        name: config: users.${name} or {} // config
      )
      (filterAttrs (_: cfg: cfg.enable or false) host.users);

    #> Collect all enabled regular users (non-service, non-guest)
    normalUsers = filterAttrs (_: u: !(elem u.role ["service" "guest"])) mergedUsers;

    #> Determine which DE/WM/DM to enable based on user preferences
    #? Priority: user config > host config > null
    interfaces = let
      # Build per-user interface config with host fallback
      userInterfaces =
        mapAttrs (name: cfg: {
          desktopEnvironment = cfg.interface.desktopEnvironment or interface.desktopEnvironment or null;
          windowManager = cfg.interface.windowManager or interface.windowManager or null;
          loginManager = cfg.interface.loginManager or interface.loginManager or null;
        })
        normalUsers;

      # Collect all unique requested environments
      desktopEnvironments = unique (filter (x: x != null) (
        attrValues (mapAttrs (_: i: i.desktopEnvironment) userInterfaces)
      ));
      windowManagers = unique (filter (x: x != null) (
        attrValues (mapAttrs (_: i: i.windowManager) userInterfaces)
      ));
      loginManagers = unique (filter (x: x != null) (
        attrValues (mapAttrs (_: i: i.loginManager) userInterfaces)
      ));
    in {
      inherit desktopEnvironments windowManagers loginManagers userInterfaces;
    };

    #> Enable flags based on collected interfaces
    enableHyprland = elem "hyprland" interfaces.windowManagers;
    enablePlasma = elem "plasma" interfaces.desktopEnvironments;
    enableGnome = elem "gnome" interfaces.desktopEnvironments;

    #> Determine login manager (prefer user choice, fallback to DE defaults)
    loginManager =
      if enablePlasma && !enableGnome
      then "sddm"
      else if enableGnome && !enablePlasma
      then "gdm"
      else if interfaces.loginManagers != []
      then head interfaces.loginManagers
      else null;

    enableSddm = loginManager == "sddm";
    enableGdm = loginManager == "gdm";

    #> Collect all unique shells from all users
    allShells = let
      shellsList = concatLists (
        attrValues (mapAttrs (_: cfg: cfg.shells or ["bash"]) normalUsers)
      );
    in
      unique shellsList;

    #> Helper to get user's interface preference (already resolved with host fallback)
    getUserInterface = name: attr:
      interfaces.userInterfaces.${name}.${attr} or null;
  in {
    #~@ System-wide NixOS users
    users.users =
      mapAttrs
      (name: cfg: let
        isNormalUser = cfg.role != "service";
      in {
        inherit isNormalUser;
        isSystemUser = !isNormalUser;
        description = cfg.description or name;

        #> Use first shell as default
        shell = getPackage {
          inherit pkgs;
          target = head (cfg.shells or ["bash"]);
        };

        password = cfg.password or null;

        extraGroups =
          (
            if elem (cfg.role or null) ["admin" "administrator"]
            then ["wheel"]
            else []
          )
          ++ (
            if
              isNormalUser
              && (config.networking.networkmanager.enable or false)
            then ["networkmanager"]
            else []
          );
      })
      mergedUsers;

    #~@ System-wide programs (not per-user)
    programs = {
      hyprland = mkIf enableHyprland {
        enable = true;
        withUWSM = true;
      };

      git = {
        enable = true;
        lfs.enable = true;
        prompt.enable = true;
      };

      gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
      };

      xwayland.enable = true;
    };

    services = {
      displayManager = {
        sddm = mkIf enableSddm {
          enable = true;
          wayland.enable = true;
        };
        gdm = mkIf enableGdm {
          enable = true;
        };

        #> Auto-login for first user with autoLogin = true
        autoLogin = let
          autoLoginUsers = filterAttrs (_: u: u.autoLogin or false) normalUsers;
          autoLoginUser =
            if autoLoginUsers != {}
            then head (attrNames autoLoginUsers)
            else null;
        in
          mkIf (autoLoginUser != null) {
            enable = true;
            user = autoLoginUser;
          };
      };

      desktopManager = {
        plasma6.enable = enablePlasma;
        gnome.enable = enableGnome;
      };
    };

    home-manager = {
      backupFileExtension = "BaC";
      overwriteBackup = true;
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = args;
      users =
        mapAttrs
        (name: cfg: let
          zen = zenVariant (attrByPath ["applications" "browser" "firefox"] null cfg);
          dp = getUserInterface name "displayProtocol";
          de = getUserInterface name "desktopEnvironment";
          wm = getUserInterface name "windowManager";
          policies = let
            hasFun = f: hostFunctionalities.validator {name = f;};
            hasCap = c: userCapabilities.validator {name = c;};

            hasInternet = hasFun "wired" || hasFun "wireless";
            hasGui = hasFun "video";
            hasAudio = hasFun "audio";
          in {
            web = hasInternet;
            webGui = hasInternet && hasGui;
            dev = hasCap "development";
            devGui = hasCap "development" && hasGui;
            media = (hasCap "multimedia" || hasCap "creation") && hasAudio && hasGui;
            webMedia = hasInternet && hasAudio && hasGui;
            productivity = (hasCap "writing" || hasCap "analysis" || hasCap "management") && hasGui;
            gaming = hasCap "gaming" && hasGui;
          };
        in {
          _module.args = {
            user = cfg // {inherit name;};
            inherit policies;
          };
          imports =
            (cfg.imports or [])
            #> Add Firefox Zen module if user prefers the Zen variant.
            ++ (
              optional (zen != null)
              inputs.firefoxZen.homeModules.${zen}
            )
            #> Add Plasma Manager module if user uses Plasma desktop
            ++ optional (de == "plasma")
            inputs.plasmaManager.homeModules.plasma-manager
            ++ [];

          home = {
            inherit stateVersion;
            sessionVariables =
              {
                USER_ROLE = cfg.role or "user";
                EDITOR = let
                  editor = attrByPath ["applications" "editor" "tty" "primary"] "nano" cfg;
                in
                  if editor == "helix"
                  then "hx"
                  else if editor == "neovim"
                  then "nvim"
                  else editor;
                VISUAL =
                  attrByPath ["applications" "editor" "gui" "primary"] (
                    if de == "gnome"
                    then "gnome-text-editor"
                    else if de == "plasma"
                    then "kate"
                    else "code"
                  )
                  cfg;
                BROWSER = let
                  browser = attrByPath ["applications" "browser" "primary"] "firefox" cfg;
                in
                  if browser == "zen"
                  then "zen-${zen}"
                  else browser;
                TERMINAL =
                  attrByPath ["applications" "terminal" "primary"] (
                    if de == "gnome"
                    then "gnome-terminal"
                    else if de == "plasma"
                    then "konsole"
                    else if wm == "hyprland"
                    then "kitty"
                    else "footclient"
                  )
                  cfg;
              }
              // (
                if dp == "wayland"
                then {
                  #? For Clutter/GTK apps
                  CLUTTER_BACKEND = "wayland";

                  #? For GTK apps
                  GDK_BACKEND = "wayland";

                  #? Required for Java UI apps on Wayland
                  _JAVA_AWT_WM_NONREPARENTING = "1";

                  #? Enable Firefox native Wayland backend
                  MOZ_ENABLE_WAYLAND = "1";

                  #? Force Chromium/Electron apps to use Wayland
                  NIXOS_OZONE_WL = "1";

                  #? Qt apps use Wayland
                  QT_QPA_PLATFORM = "wayland";

                  #? Disable client-side decorations for Qt apps
                  QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";

                  #? Auto scale for HiDPI displays
                  QT_AUTO_SCREEN_SCALE_FACTOR = "1";

                  #? SDL2 apps Wayland backend
                  SDL_VIDEODRIVER = "wayland";

                  #? Allow software rendering fallback on Nvidia/VM
                  WLR_RENDERER_ALLOW_SOFTWARE = "1";

                  #? Disable hardware cursors on Nvidia/VM
                  WLR_NO_HARDWARE_CURSORS = "1";

                  #? Indicate Wayland session to apps
                  XDG_SESSION_TYPE = "wayland";
                }
                else {}
              );
            packages =
              (map (shell:
                getPackage {
                  inherit pkgs;
                  target = shell;
                })
              allShells)
              ++ (
                if wm == "hyprland"
                then [pkgs.kitty]
                else []
              )
              ++ (
                if de == "plasma"
                then
                  with pkgs;
                    [
                      karp
                    ]
                    ++ (with kdePackages; [
                      yakuake
                      koi
                      krohnkite
                    ])
                else []
              )
              ++ [];
          };

          #> Enable shells in home-manager
          programs = {
            bash.enable = elem "bash" (cfg.shells or []);
            zsh.enable = elem "zsh" (cfg.shells or []);
            fish.enable = elem "fish" (cfg.shells or []);
            nushell.enable = elem "nushell" (cfg.shells or []);
            zen-browser = mkIf (zen != null) {
              enable = true;
              package =
                inputs.firefoxZen.packages.${system}.${zen} or
              (throw "Firefox Zen variant '${zen}' not found for system '${system}'");
            };
          };

          wayland.windowManager.hyprland.enable = wm == "hyprland";
        })
        normalUsers;
    };
  };
in {
  inherit
    mkHosts
    mkUsers
    ;
}
