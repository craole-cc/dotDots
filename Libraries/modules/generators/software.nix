{lib, ...}: let
  inherit (lib.attrsets) getAttr hasAttr;
  inherit (lib.debug) traceIf;
  inherit (lib.lists) elem any;
  inherit (lib.modules) mkIf;
  inherit (lib.strings) concatStringsSep hasInfix hasPrefix isString optionalString toLower;

  mkNix = {host, ...}: {
    system = {
      stateVersion = host.stateVersion or "25.11";
    };

    nix = {
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
          "pipe-operators"
        ];
        max-jobs = host.specs.cpu.cores or "auto";
        trusted-users = ["root" "@wheel"];
      };
    };

    systemd.services = {
      nix-daemon.serviceConfig.LimitNOFILE = lib.mkForce "65536 1048576";
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

  mkClean = {host, ...}: {
    programs.nh = {
      enable = true;
      clean = {
        enable = true;
        extraArgs = "--keep-since 3d --keep 5";
      };
      flake = host.paths.dots;
    };
  };

  exports = {inherit mkNix mkBoot mkClean;};
in
  exports // {_rootAliases = exports;}
