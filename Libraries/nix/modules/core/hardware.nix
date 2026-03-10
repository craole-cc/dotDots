{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) getAttr genAttrs hasAttr mapAttrs optionalAttrs;
  inherit (lib.lists) any elem optionals;
  inherit (lib.debug) traceIf;
  inherit (lib.modules) mkIf;
  inherit (lib.strings) concatStringsSep hasInfix hasPrefix isString optionalString toLower;
  inherit (_.lists.predicates) isIn;
  hasAudio = host: isIn "audio" (host.functionalities or []);

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
  mkSwapDevice = s: {device = s.device;};

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
      interfaces = genAttrs networkDevices (_: {useDHCP = hasNetwork;});
      firewall = {
        enable = firewall.enable or false;
        allowedTCPPorts = firewall.tcp.ports or [];
        allowedTCPPortRanges = firewall.tcp.ranges or [];
        allowedUDPPorts = firewall.udp.ports or [];
        allowedUDPPortRanges = firewall.udp.ranges or [];
      };
    };

    environment.systemPackages = optionals hasNetwork (with pkgs; [
      speedtest-cli
      speedtest-go
      mtr
      curl
      wget
      tldr
    ]);

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
    bootLoader = toLower (host.interface.bootLoader or "systemd-boot");
    bootLoaderTimeout = host.interface.bootLoaderTimeout or 5;
    efiSysMountPoint = host.devices.boot.efiSysMountPoint or "/boot";

    isSystemdBoot = hasInfix "system" bootLoader;
    isRefind = hasInfix "refind" bootLoader;
    isGrub = hasInfix "grub" bootLoader;

    validBootLoaderPatterns = ["system" "refind" "grub"];
    hasValidBootLoader = any (pattern: hasInfix pattern bootLoader) validBootLoaderPatterns;

    functionalities = host.functionalities or [];
    hasDualBoot = any (f:
      hasInfix "dualboot" (toLower f)
      || hasInfix "dual-boot" (toLower f))
    functionalities;
    hasEfi = elem "efi" functionalities;

    kernel = rec {
      default = pkgs.linuxPackages;
      requested = host.packages.kernel or null;

      #> Check if the requested kernel package exists in pkgs
      exists = requested != null && hasAttr requested pkgs;

      #> Get the actual kernel packages set
      packages =
        if exists
        then getAttr requested pkgs
        else default;

      #> Determine which kernel to use with proper tracing
      selected =
        traceIf (requested != null && exists)
        "✓ Using kernel: ${requested} (${packages.kernel.version or "unknown"})"
        (traceIf (requested != null && !exists)
          "⚠️  Kernel '${requested}' not found in pkgs, using default (${default.kernel.version})"
          (traceIf (requested == null)
            "ℹ Using default kernel (${default.kernel.version})"
            packages));
    };
  in {
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
        assertion = kernel.requested == null || kernel.exists;
        message = ''
          Requested kernel '${kernel.requested}' does not exist in pkgs.
          Available kernel packages start with: linuxPackages*
          Examples: linuxPackages_cachyos, linuxPackages_cachyos-lto, linuxPackages_zen
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
      kernelPackages = kernel.selected;

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

  exports = {
    inherit
      # mkFileSystem
      mkFileSystems
      # mkSwapDevice
      mkAudio
      mkNetwork
      mkBoot
      ;
  };
in
  exports
  // {
    # _rootAliases = {
    #   inherit
    #     (exports)
    #     mkFilesystems
    #     mkAudio
    #     mkNetwork
    #     mkBoot
    #     ;
    # };
  }
