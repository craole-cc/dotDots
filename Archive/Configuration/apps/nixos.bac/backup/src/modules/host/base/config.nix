{
  config,
  lib,
  modulesPath,
  ...
}:
let
  #| Internal Imports
  inherit (config.DOTS) Active;
  inherit (Active) host;

  #| External Imports
  # inherit (builtins) toString;
  inherit (lib.modules) mkIf mkDefault mkForce;
  inherit (lib.options) mkOption;
  inherit (lib.types) attrs;

  hostConfig =
    with host;
    if enable then
      {
        boot =
          if (machine != "server") then
            {
              loader = with boot; {
                systemd-boot = {
                  enable = loader == "systemd-boot";
                  inherit configurationLimit;
                };
                grub = {
                  enable = loader == "grub";
                  efiSupport = isEfi;
                  useOSProber = allowDualBoot;
                  default = "saved";
                  splashImage = null;
                  mirroredBoots = [
                    {
                      devices = [ "nodev" ];
                      path = "/boot";
                    }
                  ];
                  inherit configurationLimit theme;
                };
                efi.canTouchEfiVariables = isEfi;
                inherit timeout;
              };
            }
          else
            { };

        environment = {
          variables = {
            # FLAKE = mkIf (flake != null) (mkForce (toString flake));
            CONF = mkForce (toString paths.conf);
          };
          # shellAliases.Flake = mkIf (flake != null) (mkForce ("NixOS --flake ${toString flake}#${name}"));
        };

        location = with location; {
          inherit longitude latitude;
          provider = if (latitude == null || longitude == null) then "geoclue2" else "manual";
        };

        networking = {
          hostName = name;
          hostId = id;
          networkmanager.enable = machine != "server";
        };

        time = {
          inherit (location) timeZone;
          hardwareClockInLocalTime = boot.allowDualBoot;
        };

        nix = {
          gc = {
            automatic = true;
            dates = "weekly"; # TODO: Add an option for this, maybe
            options = "--delete-older-than 7d";
          };
          settings = {
            auto-optimise-store = true;
            system-features = [
              "big-parallel"
              "kvm"
              "recursive-nix"
              "nixos-test"
            ];
            experimental-features = [
              "nix-command"
              "flakes"
              "repl-flake"
            ];
          };
        };

        nixpkgs = {
          # hostPlatform = processor.arch;
          hostPlatform = lib.mkDefault "x86_64-linux";
        };

        powerManagement = {
          cpuFreqGovernor = mkDefault processor.mode;
        };

        security = {
          sudo = {
            execWheelOnly = true;
            wheelNeedsPassword = false; # TODO: This is supposedly unsafe
          };
        };

        system = {
          inherit stateVersion;
        };
      }
    else
      { };
in
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  options.DOTS.Config.host = mkOption {
    description = "Config options to pass to the actual system config";
    default = hostConfig;
    type = attrs;
  };

  config = {
    inherit (hostConfig)
      boot
      environment
      location
      networking
      time
      nix
      nixpkgs
      powerManagement
      security
      system
      ;

    # nixpkgs = {
    #   # hostPlatform = processor.arch;
    #   hostPlatform = mkForce "x86_64-linux";
    # };
  };
  # config.boot.loader.grub.configurationLimit = hostConfig.boot.loader.grub.configurationLimit;
}
