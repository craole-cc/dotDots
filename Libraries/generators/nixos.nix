{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) attrValues attrNames attrByPath filterAttrs genAttrs mapAttrs;
  inherit (lib.lists) any concatLists elem head length optional unique;
  inherit (lib.modules) mkDefault mkIf;
  inherit (lib.strings) hasInfix;
  inherit (_.generators.firefox) zenVariant;
  inherit (_.attrsets.resolution) getPackage;

  # Build a single sudo.extraRules entry granting passwordless root access
  # for a specific username.
  mkAdmin = name: {
    # Apply this rule only to the named user.
    users = [name];

    # Allow that user to run any command as any user/group, without password.
    # Equivalent to:  name ALL=(ALL:ALL) NOPASSWD: ALL
    commands = [
      {
        command = "ALL";
        options = [
          "SETENV"
          "NOPASSWD"
        ];
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
                    gc = {
                      automatic = true;
                      persistent = true;
                      dates = "weekly";
                      options = "--delete-older-than 5d";
                    };

                    optimise = {
                      automatic = true;
                      persistent = true;
                      dates = "weekly";
                    };

                    settings = {
                      auto-optimise-store = true;
                      experimental-features = [
                        "nix-command"
                        "flakes"
                        "pipe-operators"
                      ];
                      max-jobs = specs.cpu.cores or "auto";
                      substituters = ["https://cache.nixos.org/"];
                      trusted-substituters = [
                        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                        "https://hydra.nixos.org/"
                      ];
                      trusted-users = [
                        "root"
                        "@wheel"
                      ];
                    };

                    extraOptions = ''
                      download-buffer-size = 524288000
                    '';
                  };

                  nixpkgs = {
                    hostPlatform = system;
                    config.allowUnfree = packages.allowUnfree or false;
                  };

                  boot = {
                    kernelPackages = mkIf ((packages.kernel or null) != null) pkgs.${packages.kernel};
                    loader = {
                      systemd-boot.enable = interface.bootLoader or null == "systemd-boot";
                      efi.canTouchEfiVariables = true;
                      timeout = 1;
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
                    map mkSwapDevice swap;

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
                })
            ]
            ++ [
              inputs.nixosHome.nixosModules.home-manager
              {
                home-manager = {
                  backupFileExtension = "BaC";
                  overwriteBackup = true;
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  extraSpecialArgs = args;
                };
              }
            ]
            ++ [
              (mkUsers {
                allUsers = users;
                hostUsers = host.users;
                inherit (host) stateVersion;
                inherit inputs system;
              })
            ];
        }
    )
    hosts;

  mkUsers = {
    allUsers,
    hostUsers,
    stateVersion,
    system,
    inputs,
  }: {
    config,
    pkgs,
    ...
  }: let
    #> Merge user config from API/users/ with host-specific settings
    users =
      mapAttrs (
        name: config: allUsers.${name} or {} // config
      )
      (filterAttrs (_: cfg: cfg.enable or false) hostUsers);

    #> Collect all enabled regular users (non-service, non-guest)
    regularUsers = filterAttrs (_: u: !(elem u.role ["service" "guest"])) users;

    enableHyprland = any (
      cfg: (cfg.interface.windowManager or "") == "hyprland"
    ) (attrValues regularUsers);

    enablePlasma = any (
      cfg: (cfg.interface.desktopEnvironment or "") == "plasma"
    ) (attrValues regularUsers);

    enableGnome = any (
      cfg: (cfg.interface.desktopEnvironment or "") == "gnome"
    ) (attrValues regularUsers);

    #> Collect all unique shells from all users
    allShells = let
      shellsList = concatLists (
        attrValues (mapAttrs (_: cfg: cfg.shells or ["bash"]) users)
      );
    in
      unique shellsList;
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
      users;

    #~@ System-wide programs (not per-user)
    programs.hyprland = mkIf enableHyprland {
      enable = true;
      withUWSM = true;
    };

    services = {
      displayManager = {
        sddm = mkIf enablePlasma {
          enable = true;
          wayland.enable = true;
          # theme = "sddm-astronaut";
        };
        gdm = mkIf enableGnome {
          enable = true;
        };
      };
      desktopManager = {
        plasma6.enable = enablePlasma;
        gnome.enable = enableGnome;
      };
    };

    home-manager.users =
      mapAttrs
      (name: cfg: let
        zen = attrByPath ["applications" "browser" "firefox"] null cfg;
        de = attrByPath ["interface" "desktopEnvironment"] null cfg;
        wm = attrByPath ["interface" "windowManager"] null cfg;
      in {
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
          sessionVariables = {
            USER_ROLE = cfg.role or "user";
            EDITOR = attrByPath ["applications" "editor" "tty" "primary"] "nano" cfg;
            VISUAL =
              attrByPath ["applications" "editor" "gui" "primary"] (
                if de == "gnome"
                then "gnome-text-editor"
                else if de == "plasma"
                then "kate"
                else "code"
              )
              cfg;
            BROWSER = attrByPath ["applications" "browser" "primary"] "firefox" cfg;
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
          };
          packages =
            (map (shell:
              getPackage {
                inherit pkgs;
                target = shell;
              })
            allShells)
            ++ (
              if enableHyprland
              then [pkgs.kitty]
              else []
            );
        };

        #> Enable shells in home-manager
        programs = {
          # starship.enable = hasInfix "starship" (cfg.interface.prompt or "");
          # oh-my-posh.enable = hasInfix "posh" (cfg.interface.prompt or "");
          bash.enable = elem "bash" (cfg.shells or []);
          zsh.enable = elem "zsh" (cfg.shells or []);
          fish.enable = elem "fish" (cfg.shells or []);
          nushell.enable = elem "nushell" (cfg.shells or []);
          zen-browser =
            mkIf (zen != null) {
              enable = true;
              package =
                if zen == null
                then null
                else inputs.firefoxZen.packages.${system}.${zen} or
          (throw "Firefox Zen variant '${zen}' not found for system '${system}'");
            };
        };

        wayland.windowManager.hyprland.enable = wm == "hyprland";
      }) (filterAttrs (_: u: !(elem u.role ["service" "guest"])) users);
  };
in {
  inherit
    mkHosts
    mkUsers
    ;
}
