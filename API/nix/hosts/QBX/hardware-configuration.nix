{
  config,
  pkgs,
  modulesPath,
  lib,
  ...
}: let
  inherit (lib.modules) mkDefault;
in {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  # ==================== HARDWARE ====================
  hardware = {
    cpu.amd.updateMicrocode = true;
    enableAllFirmware = true;
    amdgpu.initrd.enable = true;

    graphics.enable = true;

    nvidia = {
      open = false;
      package = config.boot.kernelPackages.nvidiaPackages.production;
      forceFullCompositionPipeline = true;
      modesetting.enable = true;
      powerManagement.enable = false;
      nvidiaPersistenced = false;

      prime = {
        # AMD Granite Ridge iGPU: 0c:00.0 → 12 decimal
        amdgpuBusId = "PCI:12:0:0";
        # NVIDIA GTX 1050 Ti: 01:00.0
        nvidiaBusId = "PCI:1:0:0";
        # AMD is the Wayland render node; NVIDIA outputs are PRIME-linked to it.
        # Allows Hyprland to drive NVIDIA-connected monitors AND the optional
        # AMD mobo port (3rd monitor) simultaneously.
        reverseSync.enable = true;
      };
    };

    bluetooth = {
      enable = true;
      settings.General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };
  };

  # ==================== BOOT ====================
  boot = {
    kernelPackages = mkDefault pkgs.linuxPackages_latest;
    extraModulePackages = [];

    # Force nvidia_drm KMS via modprobe — more reliable than kernel params on 6.12+.
    # This ensures modeset/fbdev are applied before the module loads rather than
    # as parse-order-dependent kernel params.
    extraModprobeConfig = ''
      options nvidia_drm modeset=1 fbdev=1
    '';

    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
      # amdgpu first → becomes card1 (Wayland render node for reverseSync).
      # nvidia_drm last → registers card0 PRIME-linked to card1.
      kernelModules = [
        "amdgpu"
        "kvm-amd"
        "nvidia"
        "nvidia_modeset"
        "nvidia_uvm"
        "nvidia_drm"
      ];
    };

    loader = {
      systemd-boot.enable = mkDefault true;
      efi.canTouchEfiVariables = mkDefault true;
      timeout = mkDefault 5;
    };

    kernelParams = [
      # NVIDIA registry tweaks (module options, not KMS — that's in extraModprobeConfig)
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
      "nvidia.NVreg_EnableS0ixPowerManagement=1"
      "nvidia.NVreg_TemporaryFilePath=/var/tmp"

      # AMD GPU + CPU
      "amdgpu.modeset=1"
      "amd_pstate=active"

      # Evict the EFI/VESA framebuffer so it can't squat on the NVIDIA PCI slot.
      # simpledrm is blacklisted below as belt-and-suspenders for kernel 6.12+.
      "video=efifb:off"
      "video=vesa:off"

      # Force-probe the AMD mobo output for the optional 3rd monitor.
      # Safe to keep even when monitor is absent; remove if it causes issues.
      "video=card1-HDMI-A-2:e"

      # Blacklist nouveau
      "rd.driver.blacklist=nouveau"
      "modprobe.blacklist=nouveau"

      # Stability
      "nowatchdog"
      "mitigations=off"

      "loglevel=4"
      "lsm=landlock,yama,bpf"
    ];

    # simpledrm: prevents EFI framebuffer from claiming the NVIDIA PCI slot on 6.12+.
    # video=efifb:off alone is insufficient on newer kernels.
    blacklistedKernelModules = ["nouveau" "simpledrm"];
  };

  # ==================== DISPLAY / WAYLAND ====================
  # With reverseSync, AMD (card1) is the Wayland render device.
  # WLR_DRM_DEVICES ensures Hyprland opens card1 so PRIME-linked
  # NVIDIA outputs (your two monitors) are visible alongside the
  # optional AMD mobo port.
  environment.sessionVariables.WLR_DRM_DEVICES = "/dev/dri/card1";

  # amdgpu must be listed first — sets init order so AMD registers before NVIDIA.
  services.xserver.videoDrivers = ["amdgpu" "nvidia"];
}
