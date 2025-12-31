{lib, ...}: let
  inherit (lib.attrsets) filterAttrsRecursive mapAttrs' mapAttrs;
  inherit (lib.lists) elem any;
  inherit (lib.modules) mkIf;
  inherit (lib.strings) concatStringsSep hasInfix hasPrefix isString optionalString toLower;

  mkPkgs = {
    host,
    inputs,
    ...
  }: {
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

    nixpkgs = let
      allowUnfree = host.packages.allowUnfree or false;
      getSystem = final: final.stdenv.hostPlatform.system;
      # nixpkgs-stable = inputs.nixP
    in {
      hostPlatform = host.system;
      config = {inherit allowUnfree;};

      overlays = [
        #~@ Stable
        (final: prev: {
          fromStable = import inputs.nixpkgs-stable {
            system = getSystem final;
            config = {inherit allowUnfree;};
          };
        })

        #~@ Unstable
        (final: prev: {
          fromUnstable = import inputs.nixpkgs-unstable {
            system = getSystem final;
            config = {inherit allowUnfree;};
          };
        })

        #~@ Flake inputs
        #? Flattened packages (higher priority)
        (final: prev: let
          system = prev.stdenv.hostPlatform.system;
        in
          filterAttrsRecursive (name: value: value != null) (
            mapAttrs' (_name: pkgsSet: {
              name = _name;
              value = pkgsSet.${system}.${"default"} or null;
            })
            inputs.packages
          ))

        #? Categorized (lower priority, for browsing)
        (final: prev: {
          fromInputs = mapAttrs (_: pkgs: pkgs.${prev.stdenv.hostPlatform.system} or {}) inputs.packages;
        })
      ];
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
      kernelPackages =
        mkIf ((host.packages.kernel or null) != null)
        pkgs.${host.packages.kernel};

      loader = {
        #~@ systemd-boot configuration
        systemd-boot = {
          enable = isSystemdBoot;
          configurationLimit = mkIf isSystemdBoot 10;
          editor = false; # Security
          memtest86.enable = true;
          # themes = [pkgs.nordic-theme];
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

      #~@ Support for available kernel modules
      initrd.availableKernelModules = host.modules or [];
    };
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

  exports = {inherit mkPkgs mkBoot mkClean;};
in
  exports // {_rootAliases = exports;}
