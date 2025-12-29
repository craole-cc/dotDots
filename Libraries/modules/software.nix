{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.lists) elem any;
  inherit (lib.modules) mkIf;
  inherit (lib.strings) concatStringsSep hasInfix hasPrefix isString optionalString toLower;
  inherit (_.lists.predicates) isIn;

  mkNix = {
    host,
    inputs,
    ...
  }: {
    system = {
      stateVersion = host.stateVersion or "25.11";
    };

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

    nixpkgs = let
      allowUnfree = host.packages.allowUnfree or false;
      getSystem = final: final.stdenv.hostPlatform.system;
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
        (final: prev: {
          fromInputs = mapAttrs (_: pkgs: pkgs.${getSystem final} or {}) inputs.packages;
        })
      ];
    };
  };

  mkLocale = {host, ...}: let
    loc = host.localization or {};
  in {
    time = {
      timeZone = loc.timeZone or null;
      hardwareClockInLocalTime = isIn "dualboot-windows" (host.functionalities or []);
    };

    location = {
      latitude = loc.latitude or null;
      longitude = loc.longitude or null;
      provider = loc.locator or "geoclue2";
    };

    i18n = {
      defaultLocale = loc.defaultLocale or null;
    };
  };

  mkFonts = {
    pkgs,
    packages ? (with pkgs; [
      #~@ Monospace
      maple-mono.NF
      monaspace
      victor-mono

      #~@ System
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
    ]),
    emoji ? ["Noto Color Emoji"],
    monospace ? ["Maple Mono NF" "Monaspace Radon"],
    serif ? ["Noto Serif"],
    sansSerif ? ["Noto Sans"],
    ...
  }: {
    fonts = {
      inherit packages;
      enableDefaultPackages = true;
      fontconfig = {
        enable = true;
        hinting = {
          enable = true; # TODO: This should depend on the host specs
          style = "slight";
        };
        antialias = true;
        subpixel.rgba = "rgb";
        defaultFonts = {inherit emoji monospace serif sansSerif;};
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
        };

        #~@ rEFInd configuration
        refind = {
          enable = isRefind;
          extraConfig = mkIf isRefind ''
            timeout ${toString bootLoaderTimeout}
            use_graphics_for linux
            scanfor manual,external,optical,netboot

            # Theme and UI
            resolution 1920 1080
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
  exports = {inherit mkNix mkLocale mkFonts mkBoot;};
in
  exports // {_rootAliases = exports;}
