{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types;
  inherit (config.nixpkgs.localSystem) isEfi;
  inherit (lib.attrsets)
    filterAttrs
    attrNames
    attrValues
    mapAttrs
    isAttrs
    ;
  inherit (lib.lists)
    length
    head
    elem
    elemAt
    ;
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.strings)
    concatStringsSep
    fileContents
    stringLength
    substring
    ;
  inherit (lib.filesystem) pathIsRegularFile;

  #| Extended Imports
  inherit (config) DOTS;
  base = "modules";
  mod = "host";
  cfg = DOTS.${base}.${mod};
  alpha = DOTS.lib.fetchers.currentUser;

  inherit (DOTS) hosts enums;
in
{
  options.DOTS.${base}.${mod} = mkOption {
    description = "Module options for each host";
    default =
      modName: modPath:
      let
        cfg = hosts.${modName};
      in
      {
        enable = mkEnableOption "Enable host: ${modName}";

        name = mkOption {
          description = "Name of the host";
          default = modName;
        };

        paths = {
          config = mkOption {
            description = "Path to the configuration";
            default = modPath;
          };
        };

        stateVersion = mkOption {
          description = "The NixOS version at the time of installation";
          default = "24.05";
          type = with types; nonEmptyStr;
        };

        id = mkOption {
          description = ''
            The 32-bit host ID of the machine, formatted as 8 hexadecimal characters.

            Generate a random 32-bit ID using the following commands:
            `head -c 8 /etc/machine-id`
            `head -c4 /dev/urandom | od -A none -t x4`
          '';
          default =
            let
              machineId = /etc/machine-id;
              devUrandom = pkgs.writeShellScriptBin "random-hex" ''
                hexdump -n 4 -e '/1 "%02x"' -v /dev/urandom
              '';

              idFile =
                if pathIsRegularFile machineId && stringLength (fileContents machineId) == 32 then
                  fileContents machineId
                else
                  devUrandom; # TODO: This is not working. How to run random-hex shellscript?
            in
            substring 0 8 idFile;
          type = with types; nullOr str;
        };

        base = mkOption {
          description = "The base type of the client.";
          default = "common";
          type = with types; enum enums.host.base;
        };

        processor = {
          cpu = mkOption {
            description = "CPU configuration";
            default = "default";
            type = with types; enum enums.host.processor.cpu;
          };

          mode = mkOption {
            description = "CPU scaling governor";
            default =
              if
                (elem cfg.base [
                  "chromebook"
                  "raspberry-pi"
                ])
              then
                "ondemand"
              else if (elem cfg.base [ "laptop" ]) then
                "powersave"
              else
                "performance";
            type = with types; enum enums.host.processor.mode;
          };

          arch = mkOption {
            description = "The platform type of the client. One of {platform}";
            default =
              if
                (elem cfg.processor.cpu [
                  "amd64"
                  "amd"
                  "intel"
                  "x86_64"
                ])
              then
                "x86_64-linux"
              else
              #TODO: Add support for macs
                "aarch64-linux";
            # default = "x86_64-linux";
            type = with types; enum enums.host.processor.arch;
          };

          gpu = mkOption {
            description = "The main uses of this client. Any of {gpu}";
            default = cfg.processor.cpu.brand;
            type = with types; enum enums.host.processor.gpu;
          };
        };

        people = mkOption {
          description = "Users and permissions.";
          default = [
            {
              name = alpha;
              isElevated = true;
            }
          ];
          type =
            let
              user = types.submodule {
                options = {
                  name = mkOption {
                    description = "Font name, as used by fontconfig.";
                    type = with types; enum enums.user.configuration;
                  };
                  isElevated = mkOption {
                    type = with types; bool;
                    description = "Package providing the font.";
                  };
                };
              };
            in
            types.nonEmptyListOf user;
        };

        context = mkOption {
          description = "The main uses of this client. Any of ${enums.host.context}";
          default =
            if
              elem base [
                "chromebook"
                "laptop"
              ]
            then
              enums.host.context
            else if
              elem base [
                "server"
                "raspberry-pi"
              ]
            then
              [
                "minimal"
                "development"
              ]
            else
              [ "minimal" ];
          type = with types; listOf (enum (enums.host.context ++ [ "minimal" ]));
        };

        location = {
          timeZone = mkOption {
            description = "The time zone used for displaying time and dates.";
            default = "America/Jamaica";
            type = with types; nullOr str;
          };

          latitude = mkOption {
            description = "The latitudinal coordinate as a decimal between `-90.0` and `90.0`";
            default = 18.015;
            type = with types; float;
          };

          longitude = mkOption {
            description = "The longitudinal coordinate as a decimal between `-180.0` and `180.0`";
            default = -77.5;
            type = with types; float;
          };
        };

        packages = mkOption {
          description = "System packages";
          default = with pkgs; [
            nixd
            nixfmt-rfc-style
            helix
          ];
          type = with types; listOf package;
        };

        boot = {
          theme = mkOption {
            description = "The grub theme to use if grub is active";
            default = pkgs.fetchFromGitHub {
              owner = "shvchk";
              repo = "fallout-grub-theme";
              rev = "80734103d0b48d724f0928e8082b6755bd3b2078";
              sha256 = "sha256-7kvLfD6Nz4cEMrmCA9yq4enyqVyqiTkVZV5y4RyUatU=";
            };
            type = with types; package;
          };

          timeout = mkOption {
            description = "Total number of seconds to display the boot menu";
            default = 1;
            type = with types; nullOr int;
          };

          loader = mkOption {
            description = "The bootloader to use";
            default = "grub";
            type = with types; enum enums.host.manager.boot;
          };

          isEfi = mkEnableOption "Is an EFI system" // {
            default = isEfi;
          };

          allowDualBoot = mkEnableOption "Allow dual boot" // {
            default = false;
          };

          configurationLimit = mkOption {
            description = "Configuration limit";
            default =
              if
                (elem cfg.base [
                  "chromebook"
                  "raspberry-pi"
                ])
              then
                5
              else
                50;
            type = with types; int;
          };

          kernel = {
            initrd = mkOption {
              description = "";
              default = [ ];
              type = with types; listOf str;
            };
            modules = mkOption {
              description = "";
              default =
                [ ]
                ++ (
                  with cfg.processor;
                  if
                    (elem cpu [
                      "intel"
                      "amd"
                    ])
                  then
                    [ "kvm-${cpu}" ]
                  else
                    [ ]
                );
              type = with types; listOf str;
            };
            packages = mkOption {
              description = "";
              default = pkgs.linuxPackages_latest;
              type = with types; either path package;
            };
          };
        };

        mount = {
          fileSystems = mkOption {
            description = "Mountpoints";
            default = { };
            type = with types; attrs;
          };

          swap = mkOption {
            description = "Swap devices";
            default = [ ];
          };
        };

        devices = {
          luks = mkOption {
            description = "Encrypted (luks) devices";
            default = { };
            type = with types; attrsOf attrs;
          };

          network = mkOption {
            description = "List of networking interfaces to enable";
            default = [ ];
            type = with types; listOf str;
          };
        };
      };
    type = with types; raw;
  };
}
