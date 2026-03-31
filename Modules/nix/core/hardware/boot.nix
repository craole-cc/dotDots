{
  config,
  host,
  lix,
  pkgs,
  top,
  ...
}: let
  dom = "hardware";
  mod = "boot";
  cfg = config.${top}.${dom}.${mod};
  hw = host.hardware;

  inherit (lix.attrsets.access) getAttr;
  inherit (lix.attrsets.predicates) hasAttr;
  inherit (lix.debug.tracing) traceIf;
  inherit (lix.modules.construction) mkIf;
  inherit (lix.lists.enums.gui) bootLoaders;
  inherit (lix.lists.predicates) any;
  inherit (lix.options.construction) mkTrue mkOption;
  inherit (lix.strings.construction) concatStringsSep optionalString;
  inherit (lix.strings.predicates) hasInfix hasPrefix isString;
  inherit (lix.types.combinators) enum;
  inherit (lix.types.primitives) int str;
  inherit (pkgs) linuxPackages;

  validPatterns = ["system" "refind" "grub"];
  kernel = let
    selection = host.packages.kernel or null;
    exists = selection != null && hasAttr selection pkgs;
    pkgs' =
      if exists
      then getAttr selection pkgs
      else linuxPackages;
    packages =
      traceIf exists
      "✓ Using kernel: ${selection} (${pkgs'.kernel.version or "unknown"})"
      (traceIf (!exists)
        "⚠️  Kernel '${selection}' not found, using default (${linuxPackages.kernel.version})"
        (traceIf (selection == null)
          "ℹ Using default kernel (${linuxPackages.kernel.version})"
          pkgs'));
  in {inherit packages;};
in {
  options.${top}.${dom}.${mod} = {
    enable = mkTrue mod;
    loader = mkOption {
      description = "Boot loader";
      default = hw.boot.loader;
      type = enum bootLoaders.values;
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
        assertion = any (p: hasInfix p cfg.loader) validPatterns;
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
      kernelPackages = kernel.packages;

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

    environment.systemPackages = with pkgs; [
      efibootmgr
    ];
  };
}
