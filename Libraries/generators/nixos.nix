{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) attrValues attrByPath filterAttrs genAttrs mapAttrs;
  inherit (lib.lists) any concatLists elem head optional unique;
  inherit (lib.modules) mkDefault mkIf;
  inherit (lib.strings) hasInfix;
  inherit (_.generators.firefox) zenVariant;
  inherit (_.attrsets.resolution) getPackage;

  mkNetworkInterface = _: {useDHCP = mkDefault true;};

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
      in
        inputs.nixosCore.lib.nixosSystem {
          inherit system;
          specialArgs = args;
          modules =
            [
              (with host; let
                hasAudio = elem "audio" functionalities;
              in
                {pkgs, ...}: {
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
                    interfaces = genAttrs (devices.network or []) mkNetworkInterface;

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

                  security.rtkit.enable = hasAudio;
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
                inherit (host.specs) platform;
                inherit inputs;
              })
            ];
        }
    )
    hosts;

  mkUsers = {
    allUsers,
    hostUsers,
    stateVersion,
    platform,
    inputs,
  }: {pkgs, ...}: let
    #> Merge user config from API/users/ with host-specific settings
    users =
      mapAttrs (
        name: config: allUsers.${name} or {} // config
      )
      (filterAttrs (_: cfg: cfg.enable or false) hostUsers);

    #> Collect all enabled regular users (non-service, non-guest)
    regularUsers = filterAttrs (_: u: !(elem u.role ["service" "guest"])) users;

    hyprlandNeeded = any (
      cfg: ((cfg.interface or {}).windowManager or "") == "hyprland"
    ) (attrValues regularUsers);

    #> Collect all unique shells from all users
    allShells = let
      shellsList = concatLists (
        attrValues (mapAttrs (_: cfg: cfg.shells or ["bash"]) users)
      );
    in
      unique shellsList;
  in {
    # imports = [../../Configuration/hosts/QBX/configuration.nix]; # TODO: Temporary until all setting are migrated.
    # inherit (host) imports;

    #~@ System-wide NixOS users
    users.users =
      mapAttrs
      (username: cfg: {
        isNormalUser = cfg.role != "service";
        isSystemUser = cfg.role == "service";
        description = cfg.description or username;
        #> Use first shell as default
        shell = getPackage {
          inherit pkgs;
          target = head (cfg.shells or ["bash"]);
        };
        password = cfg.password or null;
        extraGroups =
          if elem cfg.role ["admin" "administrator"]
          then ["wheel"]
          else [];
      })
      users;

    #~@ System-wide programs (not per-user)
    programs.hyprland = mkIf hyprlandNeeded {
      enable = true;
      withUWSM = true;
    };
    environment.systemPackages = mkIf hyprlandNeeded [pkgs.kitty];

    home-manager.users =
      mapAttrs
      (name: cfg: let
        zen = zenVariant (attrByPath ["applications" "browser" "firefox"] null cfg);
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
          sessionVariables.USER_ROLE = cfg.role or "user";
          packages = map (shell:
            getPackage {
              inherit pkgs;
              target = shell;
            })
          allShells;
        };

        #> Enable shells in home-manager
        programs = {
          starship.enable = hasInfix "starship" (cfg.interface.prompt or "");
          oh-my-posh.enable = hasInfix "posh" (cfg.interface.prompt or "");
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
                else inputs.firefoxZen.packages.${platform}.${zen} or
          (throw "Firefox Zen variant '${zen}' not found for system '${platform}'");
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
