{
  config,
  host,
  lib,
  lix,
  pkgs,
  top,
  ...
}: let
  dom = "hardware";
  mod = "boot";
  cfg = config.${top}.${dom}.${mod};
  hw = host.hardware;

  inherit (lib.attrsets) getAttr hasAttr;
  inherit (lib.debug) traceIf;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.strings) concatStringsSep hasInfix hasPrefix isString optionalString;
  inherit (lib.types) int str;
  inherit (lix.enums) bootLoaders;

  validPatterns = ["system" "refind" "grub"];

  kernelRequested = host.packages.kernel or null;
  kernelExists = kernelRequested != null && hasAttr kernelRequested pkgs;
  kernelPkgs =
    if kernelExists
    then getAttr kernelRequested pkgs
    else pkgs.linuxPackages;
  kernelSelected =
    traceIf (kernelRequested != null && kernelExists)
    "✓ Using kernel: ${kernelRequested} (${kernelPkgs.kernel.version or "unknown"})"
    (traceIf (kernelRequested != null && !kernelExists)
      "⚠️  Kernel '${kernelRequested}' not found, using default (${pkgs.linuxPackages.kernel.version})"
      (traceIf (kernelRequested == null)
        "ℹ Using default kernel (${pkgs.linuxPackages.kernel.version})"
        kernelPkgs));
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption mod // {default = true;};
    loader = mkOption {
      description = "Boot loader";
      default = hw.boot.loader;
      type = lib.types.enum bootLoaders.values;
    };
    timeout = mkOption {
      description = "Boot loader timeout";
      default = hw.boot.timeout;
      type = int;
    };
    efiMount = mkOption {
      description = "EFI mount point";
      default = hw.boot.efiMount;
      type = str;
    };
  };

  config = mkIf cfg.enable {
    assertions = let
      isSystemd = hasInfix "system" cfg.loader;
      isRefind = hasInfix "refind" cfg.loader;
      isGrub = hasInfix "grub" cfg.loader;
    in [
      {
        assertion = builtins.any (p: hasInfix p cfg.loader) validPatterns;
        message = ''
          Invalid bootLoader '${cfg.loader}'.
          Must contain one of: ${concatStringsSep ", " validPatterns}
        '';
      }
      {
        assertion = hw.hasEfi;
        message = ''Boot loader requires EFI. Add "efi" to host.functionalities.'';
      }
      {
        assertion = cfg.timeout >= 0;
        message = "bootLoaderTimeout must be non-negative, got: ${toString cfg.timeout}";
      }
      {
        assertion = isString cfg.efiMount && hasPrefix "/" cfg.efiMount;
        message = "efiSysMountPoint must be an absolute path, got: ${toString cfg.efiMount}";
      }
      {
        assertion = !(isSystemd && isRefind);
        message = "Cannot enable both systemd-boot and refind simultaneously.";
      }
      {
        assertion = !(isSystemd && isGrub);
        message = "Cannot enable both systemd-boot and grub simultaneously.";
      }
      {
        assertion = !(isRefind && isGrub);
        message = "Cannot enable both refind and grub simultaneously.";
      }
    ];

    boot = let
      isSystemd = hasInfix "system" cfg.loader;
      isRefind = hasInfix "refind" cfg.loader;
      isGrub = hasInfix "grub" cfg.loader;
    in {
      kernelPackages = kernelSelected;

      loader = {
        systemd-boot = mkIf isSystemd {
          enable = true;
          configurationLimit = 20;
          editor = false;
          memtest86.enable = true;
          netbootxyz.enable = true;
          rebootForBitlocker = true;
        };

        refind = mkIf isRefind {
          enable = true;
          extraConfig = ''
            timeout ${toString cfg.timeout}
            use_graphics_for linux
            scanfor manual,external,optical,netboot
            resolution 1600 900
            use_nvram false
            ${optionalString hw.hasDualBoot ''
              menuentry "Windows" {
                loader \EFI\Microsoft\Boot\bootmgfw.efi
                icon \EFI\refind\icons\os_win.png
              }
            ''}
          '';
        };

        grub = mkIf isGrub {
          enable = true;
          device = "nodev";
          efiSupport = hw.hasEfi;
          useOSProber = hw.hasDualBoot;
        };

        efi = {
          canTouchEfiVariables = hw.hasEfi;
          efiSysMountPoint = cfg.efiMount;
        };

        timeout = cfg.timeout;
      };

      initrd.availableKernelModules = host.modules or [];
    };

    environment.systemPackages = [pkgs.efibootmgr];
  };
}
