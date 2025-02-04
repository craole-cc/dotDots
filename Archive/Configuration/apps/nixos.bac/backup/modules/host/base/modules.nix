{
  config,
  lib,
  pkgs,
  ...
}:
let
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
  inherit (lib.types)
    nonEmptyStr
    package
    nullOr
    bool
    str
    strMatching
    float
    enum
    attrs
    listOf
    int
    raw
    submodule
    nonEmptyListOf
    ;
  inherit (lib.filesystem) pathIsRegularFile;
in
{
  options.dot = with config.dot; {
    active.host = mkOption {
      description = "The current host configuration";
      default =
        let
          inherit (config.networking) hostName;
          inherit (sources.host.configuration) home;
          inherit (enums.host) configuration;

          enabled = rec {
            names = attrNames (filterAttrs (name: hostConfig: hostConfig.enable == true) hosts);
            count = length names;
          };

          msgEnable = ''${concatStringsSep "\n      # " (
            map (host: "config.dot.hosts." + host + ".enable = true;") configuration
          )}'';
        in
        if enabled.count == 0 then
          throw ''
            Missing host configuration. Possible solutions:

            1. Enable one of the known hosts in your configuration file: 
                {
                  ${msgEnable}
                };

            2. Create a host configuration at either of the following locations: 
                [
                  ${toString home + "/${hostName}.nix"}
                  ${toString home + "/${hostName}/default.nix"}
                ]
                
               then enable it in your configuration file via:
                { config.dot.hosts.${hostName}.enable = true; };
          ''
        else if enabled.count >= 2 then
          throw ''
            Multiple (${toString enabled.count}) hosts enabled: [ ${concatStringsSep ", " enabled.names} ] 

              Disable all but one of the known hosts: 
                {
                  ${msgEnable}
                };
          ''
        else
          hosts.${head enabled.names};
      type = attrs;
    };

    modules.host = mkOption {
      description = "Module options for each host";
      default =
        host': path':
        with hosts.${host'};
        with enums;
        {

          enable = mkEnableOption "Enable host: ${host'}";

          name = mkOption {
            description = "Name of the host";
            default = host';
          };

          paths = {
            conf = mkOption {
              description = "Path to the configuration";
              default = path';
            };
          };

          stateVersion = mkOption {
            description = "The NixOS version at the time of installation";
            default = "24.05";
            type = nonEmptyStr;
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
            type = nullOr str;
          };

          machine = mkOption {
            description = "The machine type of the client.";
            default = "common";
            type = enum enums.host.machine;
          };

          processor = with processor; {
            cpu = mkOption {
              description = "CPU configuration";
              default = "default";
              type = enum enums.host.processor.cpu;
            };

            mode = mkOption {
              description = "CPU scaling governor";
              default =
                if
                  (elem machine [
                    "chromebook"
                    "raspberry-pi"
                  ])
                then
                  "ondemand"
                else if (elem machine [ "laptop" ]) then
                  "powersave"
                else
                  "performance";
              type = enum enums.host.processor.mode;
            };

            arch = mkOption {
              description = "The platform type of the client. One of {platform}";
              default =
                if
                  (elem cpu [
                    "amd64"
                    "amd"
                    "intel"
                    "x86_64"
                  ])
                then
                  "x86_64-linux"
                else
                  "aarch64-linux";
              # default = "x86_64-linux";
              type = enum enums.host.processor.arch;
            };

            gpu = mkOption {
              description = "The main uses of this client. Any of {gpu}";
              default = cpu.brand;
              type = enum enums.host.processor.gpu;
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
                user = submodule {
                  options = {
                    name = mkOption {
                      description = "Font name, as used by fontconfig.";
                      type = enum enums.user.configuration;
                    };
                    isElevated = mkOption {
                      type = bool;
                      description = "Package providing the font.";
                    };
                  };
                };
              in
              nonEmptyListOf user;
          };

          contextAllowed = mkOption {
            description = "The main uses of this client. Any of ${host.context}";
            default =
              if
                elem machine [
                  "chromebook"
                  "laptop"
                ]
              then
                host.context
              else if
                elem machine [
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
            type = listOf (enum (host.context ++ [ "minimal" ]));
          };

          location = {
            timeZone = mkOption {
              description = "The time zone used for displaying time and dates.";
              default = "America/Jamaica";
              type = nullOr str;
            };

            latitude = mkOption {
              description = "The latitudinal coordinate as a decimal between `-90.0` and `90.0`";
              default = 18.015;
              type = float;
            };

            longitude = mkOption {
              description = "The longitudinal coordinate as a decimal between `-180.0` and `180.0`";
              default = -77.5;
              type = float;
            };
          };

          packages = mkOption {
            description = "System packages";
            default = [ ];
            type = listOf package;
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
              type = package;
            };

            timeout = mkOption {
              description = "Total number of seconds to display the boot menu";
              default = 1;
              type = nullOr int;
            };

            loader = mkOption {
              description = "The bootloader to use";
              default = "grub";
              type = enum enums.host.manager.boot;
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
                  elem machine [
                    "chromebook"
                    "raspberry-pi"
                  ]
                then
                  5
                else
                  50;
              type = int;
            };

            kernel = {
              initrd = mkOption {
                description = "";
                default = [ ];
                type = listOf str;
              };
              modules = mkOption {
                description = "";
                default = [ ];
                type = listOf str;
              };
              packages = mkOption {
                description = "";
                default = pkgs.linuxPackages;
                type = raw;
              };
            };
          };

          mount = {
            fileSystem = mkOption {
              description = "Mountpoints";
              default = { };
              type = attrs;
            };

            swap = mkOption {
              description = "Swap devices";
              default = [ ];
            };
          };

          networking = mkOption {
            description = "Networking config like DHCP";
            default = { };
          };
        };
      type = raw;
    };

    hosts =
      let
        inherit (modules) host;
        inherit (sources.host.configuration) attrs;
      in
      mapAttrs (name: path: host name path) attrs;
  };
}
