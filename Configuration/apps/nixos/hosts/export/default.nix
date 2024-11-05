{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

let
  inherit (lib.lists) elem length head;
  inherit (lib.modules) mkIf mkDefault mkForce;
  inherit (lib.options) mkOption;
  inherit (config.dot.active) host;

  cfg = config.dot.config;

  hostConfig =
    with host;
    with location;
    mkIf enable {
      boot = {
        loader =
          with boot;
          mkIf (machine != "server") {
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
      };

      environment = {
        variables = {
          # FLAKE = mkIf (flake != null) (mkForce (toString flake));
          CONF = mkForce (toString paths.conf);
        };
        # shellAliases.Flake = mkIf (flake != null) (mkForce ("NixOS --flake ${toString flake}#${name}"));
      };

      location = {
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
        hostPlatform = processor.arch;
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
    };
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./types
  ];

  options.dot.config.host = mkOption {
    default = with hostConfig; if condition == true then content else { };
  };

  config = hostConfig;
}
