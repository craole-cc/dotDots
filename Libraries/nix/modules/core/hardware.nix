{_, ...}: let
  meta = {
    doc = ''
      # Core Hardware [Layer 3]

      NixOS system configuration builders for host hardware concerns.

      Provides `mkBoot`, `mkAudio`, `mkFileSystems`, and `mkNetwork` to
      translate the normalized host hardware and device records into NixOS
      boot, audio, filesystem, swap, and network configuration.

      ## Boot

      `mkBoot` selects the configured systemd-boot, rEFInd, or GRUB loader,
      configures EFI mounting and boot timeouts, and resolves kernel packages
      from the host and primary user settings. It validates the boot loader,
      EFI functionality, mount point, timeout, and mutually exclusive loader
      choices. Dual-boot functionality enables Windows detection in GRUB or
      adds a Windows entry to rEFInd.

      ## Audio

      `mkAudio` enables PipeWire with ALSA, PulseAudio, JACK, and WirePlumber
      support, disables PulseAudio, and enables rtkit when the host declares
      the `audio` functionality.

      ## Filesystems

      `mkFileSystems` maps `host.devices.file` to NixOS `fileSystems`,
      preserving each device and filesystem type and including mount options
      when provided. It maps `host.devices.swap` to `swapDevices`.

      ## Network

      `mkNetwork` derives the hostname, host ID, NetworkManager and DHCP
      interface configuration, nameservers, and firewall rules from the host
      record. Network utilities are installed when network devices are
      declared. GnuPG agent support is enabled by default and can be disabled
      with `gnupgSupported = false`.
    '';

    exports = {
      internal = let
        functions = {
          inherit
            mkBoot
            mkAudio
            mkFileSystem
            mkFileSystems
            mkNetwork
            mkSwapDevice
            ;
        };
        aliases = {};
      in
        {inherit functions aliases;} // functions // aliases;
      external = {
        inherit
          mkAudio
          mkBoot
          mkFileSystems
          mkNetwork
          ;
      };
    };
  };

  inherit (_.attrsets.construction) genAttrs optionalAttrs;
  inherit (_.attrsets.predicates) hasAttr;
  inherit (_.attrsets.transformation) mapAttrs;
  inherit (_.lists.construction) optionals;
  inherit (_.lists.predicates) any isIn elem;
  inherit (_.modules) mkIf;
  inherit (_.strings.construction) concatStringsSep optionalString;
  inherit (_.strings.transformation) toLowerCase;
  inherit (_.strings.predicates) hasInfix hasPrefix isString;
  hasAudio = host: isIn "audio" (host.functionalities or []);

  mkFileSystem = _: fs: let
    base = {
      inherit (fs) device fsType;
    };
    opts = fs.options or [];
  in
    #> Combine base attributes with options if they exist.
    if opts == []
    then base
    else base // {options = opts;};
  mkSwapDevice = s: {inherit (s) device;};

  mkFileSystems = {host, ...}: {
    fileSystems = mapAttrs mkFileSystem (host.devices.file or {});
    swapDevices = map mkSwapDevice (host.devices.swap or []);
  };

  mkAudio = {host, ...}: {
    services = optionalAttrs (hasAudio host) {
      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
        wireplumber.enable = true;
      };
      pulseaudio.enable = false;
    };
    security = optionalAttrs (hasAudio host) {rtkit.enable = true;};
  };

  mkNetwork = {
    host,
    pkgs,
    gnupgSupported ? true,
    ...
  }: let
    networkDevices = host.devices.network or [];
    hasNetwork = networkDevices != [];
    access = host.access or {};
    firewall = access.firewall or {};
  in {
    networking = {
      hostName = host.name or "nixos";
      hostId = host.id or null;
      networkmanager.enable = hasNetwork;
      nameservers = access.nameservers or [];
      interfaces = genAttrs networkDevices (_: {
        useDHCP = hasNetwork;
      });
      firewall = {
        enable = firewall.enable or false;
        allowedTCPPorts = firewall.tcp.ports or [];
        allowedTCPPortRanges = firewall.tcp.ranges or [];
        allowedUDPPorts = firewall.udp.ports or [];
        allowedUDPPortRanges = firewall.udp.ranges or [];
      };
    };

    environment.systemPackages = optionals hasNetwork (
      with pkgs; [
        speedtest-cli
        speedtest-go
        mtr
        curl
        wget
        tldr
      ]
    );

    programs = {
      gnupg = optionalAttrs gnupgSupported {
        agent = {
          enable = true;
          enableSSHSupport = true;
        };
      };
    };
  };

  mkBoot = {
    host,
    pkgs,
    ...
  }: let
    bootLoader = toLowerCase (host.interface.boot.loader or host.interface.bootLoader or "systemd-boot");
    bootLoaderTimeout = host.interface.boot.timeout or host.interface.bootLoaderTimeout or 5;
    efiSysMountPoint = host.interface.boot.efiMount or host.devices.boot.efiSysMountPoint or "/boot";

    isSystemdBoot = hasInfix "system" bootLoader;
    isRefind = hasInfix "refind" bootLoader;
    isGrub = hasInfix "grub" bootLoader;

    validBootLoaderPatterns = [
      "system"
      "refind"
      "grub"
    ];
    hasValidBootLoader = any (pattern: hasInfix pattern bootLoader) validBootLoaderPatterns;

    functionalities = host.functionalities or [];
    hasDualBoot =
      any (
        f: hasInfix "dualboot" (toLowerCase f) || hasInfix "dual-boot" (toLowerCase f)
      )
      functionalities;
    hasEfi = elem "efi" functionalities;

    kernel = _.schema.kernel.resolve {
      inherit host pkgs;
      user = host.users.data.primary or {};
    };
    bareCachyOS =
      kernel.requested
      != null
      && elem (toLowerCase kernel.requested) ["cachy" "cachyos" "linux-cachyos"];
    useGenericV3 =
      bareCachyOS
      && kernel.cpu.arch == "x86_64"
      && elem (toLowerCase (kernel.cpu.microarch or "")) ["znver1" "znver2" "znver3"]
      && kernel.level == "v1"
      && hasAttr "cachyOverride" kernel.packages;
    kernelPackages =
      if useGenericV3
      then
        kernel.packages.cachyOverride {
          cachyVars =
            kernel.packages.kernel.cachyConfig.cachyVars
            // {
              "_processor_opt" = "GENERIC_V3";
            };
        }
      else kernel.packages;
    kernelWarnings =
      if useGenericV3
      then []
      else kernel.warnings;
  in {
    warnings = kernelWarnings;
    assertions = [
      {
        assertion = hasValidBootLoader;
        message = ''
          Invalid bootLoader '${host.interface.bootLoader or "systemd-boot"}'.
          Must contain one of: ${concatStringsSep ", " validBootLoaderPatterns}
          Examples: "systemd-boot", "systemd", "refind", "rEFInd", "grub", "grub2"
        '';
      }
      {
        assertion = hasEfi;
        message = ''
          Boot loader requires EFI functionality.
          Add "efi" to host.functionalities.
        '';
      }
      {
        assertion = bootLoaderTimeout >= 0;
        message = ''
          bootLoaderTimeout must be non-negative, got: ${toString bootLoaderTimeout}
        '';
      }
      {
        assertion = isString efiSysMountPoint && efiSysMountPoint != "";
        message = ''
          devices.boot.efiSysMountPoint must be a non-empty string.
          Current value: ${toString efiSysMountPoint}
        '';
      }
      {
        assertion = hasPrefix "/" efiSysMountPoint;
        message = ''
          devices.boot.efiSysMountPoint must be an absolute path.
          Current value: ${efiSysMountPoint}
        '';
      }
      {
        assertion = !(isSystemdBoot && isRefind);
        message = "Cannot enable both systemd-boot and refind simultaneously.";
      }
      {
        assertion = !(isSystemdBoot && isGrub);
        message = "Cannot enable both systemd-boot and grub simultaneously.";
      }
      {
        assertion = !(isRefind && isGrub);
        message = "Cannot enable both refind and grub simultaneously.";
      }
    ];

    boot = {
      inherit kernelPackages;

      loader = {
        #~@ systemd-boot configuration
        systemd-boot = {
          enable = isSystemdBoot;
          configurationLimit = mkIf isSystemdBoot 20;
          editor = false; # Security
          memtest86.enable = true;
          netbootxyz.enable = true;
          rebootForBitlocker = true;
        };

        #~@ rEFInd configuration
        refind = {
          enable = isRefind;
          extraConfig = mkIf isRefind ''
            timeout ${toString bootLoaderTimeout}
            use_graphics_for linux
            scanfor manual,external,optical,netboot

            # Theme and UI
            # resolution 1920 1080
            resolution 1600 900
            use_nvram false

            ${optionalString hasDualBoot ''
              # Windows dual-boot support
              menuentry "Windows" {
                loader \EFI\Microsoft\Boot\bootmgfw.efi
                icon \EFI\refind\icons\os_win.png
              }
            ''}
          '';
        };

        grub = {
          enable = isGrub;
          device = "nodev";
          efiSupport = hasEfi;
          useOSProber = hasDualBoot;
        };

        #~@ Common EFI settings
        efi = {
          canTouchEfiVariables = hasEfi;
          inherit efiSysMountPoint;
        };

        timeout = bootLoaderTimeout;
      };
      initrd = {
        availableKernelModules = host.modules or [];
      };
    };

    environment.systemPackages = with pkgs; [efibootmgr];
  };
in
  with meta.exports;
    internal
    // {
      __doc = meta.doc;
      __rootAliases = external;
    }
