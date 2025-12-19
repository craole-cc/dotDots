{
  _,
  lib,
  ...
}: let
  inherit (_.generators.home) mkUsers;
  inherit
    (lib.attrsets)
    filterAttrs
    optionalAttrs
    genAttrs
    mapAttrs
    ;
  inherit (lib.lists) elem;
  inherit (lib.modules) mkDefault mkIf;

  mkCore = {
    nixosSystem,
    users,
    hosts,
    args ? {},
  }:
    mapAttrs (name: host: let
      dots = host.paths.dots or null;
      system = host.platform or builtins.currentSystem;
    in
      mkHost {
        inherit nixosSystem;
        host =
          host
          // {
            inherit name dots system;
            users =
              mapAttrs (name: config: users.${name} or {} // config)
              (filterAttrs (_: cfg: cfg.enable or false) host.users);
          };
        extraArgs = args // {inherit dots system;};
      })
    hosts;

  mkHost = {
    host,
    nixosSystem,
    extraArgs,
  }: let
    inherit (host) name system dots;
    localization = host.localization or {};
    functionalities = host.functionalities or [];
    hasAudio = elem "audio" functionalities;
  in
    nixosSystem {
      inherit system;
      specialArgs = extraArgs;
      modules = [
        (mkUsers {inherit host extraArgs;})
        (
          {pkgs, ...}: {
            inherit (host) imports;
            system = {inherit (host) stateVersion;};

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
                max-jobs = host.specs.cpu.cores or "auto";
                # substituters = ["https://cache.nixos.org/"];
                # trusted-substituters = [
                #   "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                #   "https://hydra.nixos.org/"
                # ];
                trusted-users = ["root" "@wheel"];
              };

              # extraOptions = ''
              #   download-buffer-size = 524288000
              # '';
            };

            nixpkgs = {
              hostPlatform = system;
              config.allowUnfree = host.packages.allowUnfree or false;
            };

            boot = {
              kernelPackages = mkIf ((host.packages.kernel or null) != null) pkgs.${host.packages.kernel};
              loader = {
                systemd-boot.enable = (host.interface.bootLoader or null) == "systemd-boot";
                efi.canTouchEfiVariables = true; # TODO: Make this dynamic
                timeout = host.interface.bootLoaderTimeout or 1;
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
              mapAttrs mkFileSystem (host.devices.file or {});

            swapDevices = let
              mkSwapDevice = s: {device = s.device;};
            in
              map mkSwapDevice (host.devices.swap or []);

            networking = let
              hasNetwork = (host.devices.network or []) != [];
              mkNetworkInterface = _: {useDHCP = mkDefault hasNetwork;};
            in {
              #> System name
              hostName = name;

              #> 32-bit host ID (ZFS requirement)
              hostId = host.id or null;

              #> Enable NetworkManager if interfaces are defined
              networkmanager.enable = hasNetwork;

              #> DNS Nameservers from host config
              inherit (host.access) nameservers;

              #> Ensure DHCP is available for interfaces
              interfaces = genAttrs (host.devices.network or []) mkNetworkInterface;

              #> Configure firewall
              firewall = let
                fw =
                  host.access.firewall or {
                    tcp = {
                      ports = [];
                      ranges = [];
                    };
                    udp = {
                      ports = [];
                      ranges = [];
                    };
                  };
                inherit (fw) tcp udp;
                enable = fw.enable or false;
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

            #~@ Audio
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

            environment = {
              shellAliases =
                {
                  ll = "lsd --long --git --almost-all";
                  lt = "lsd --tree";
                  lr = "lsd --long --git --recursive";
                }
                // (
                  optionalAttrs (dots != null) {
                    edit-dots = "$EDITOR ${dots}";
                    ide-dots = "$VISUAL ${dots}";
                    push-dots = "gitui --directory ${dots}";
                    repl-host = "nix repl ${dots}#nixosConfigurations.$(hostname)";
                    repl-dots = "nix repl ${dots}#repl";
                    switch-dots = "sudo nixos-rebuild switch --flake ${dots}";
                    nxs = "push-dots; switch-dots";
                    nxu = "push-dots; switch-dots; topgrade";
                  }
                );
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
                shfmt
                shellcheck

                #~@ Tools
                cowsay
                gitui
                lm_sensors
                lsd
                lshw
                mesa-demos
                topgrade
                toybox
                speedtest-cli
                speedtest-go
              ];
            };
          }
        )
      ];
    };

  exports = {
    inherit
      mkCore
      mkHost
      ;
  };
in
  exports // {_rootAliases = exports;}
