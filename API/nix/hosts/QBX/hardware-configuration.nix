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

      prime = {
        # AMD Granite Ridge iGPU: 0c:00.0 → PCI:12:0:0
        amdgpuBusId = "PCI:12:0:0";
        # NVIDIA GTX 1050 Ti: 01:00.0 → PCI:1:0:0
        nvidiaBusId = "PCI:1:0:0";
        # AMD is the Wayland render node (card1); NVIDIA outputs (card0) are
        # PRIME-linked and appear as additional connectors under the AMD DRM device.
        # This lets Hyprland drive both the NVIDIA-connected monitors AND the
        # optional AMD motherboard port simultaneously.
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

    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
      # Load GPU drivers early so KMS is active before the display manager starts.
      # amdgpu must come first — it becomes the primary DRM device (card1) for
      # reverseSync; nvidia_drm then registers card0 and links outputs via PRIME.
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
      # NVIDIA KMS — deduplicated (kernel treats hyphens/underscores identically)
      "nvidia_drm.modeset=1"
      "nvidia_drm.fbdev=1"
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
      "nvidia.NVreg_EnableS0ixPowerManagement=1"
      "nvidia.NVreg_TemporaryFilePath=/var/tmp"

      # AMD GPU + CPU
      "amdgpu.modeset=1"
      "amd_pstate=active"

      # Prevent the EFI/VESA framebuffer from claiming the NVIDIA card before
      # nvidia_drm can register it — this was causing card0-Unknown-1 / 800x600
      "video=efifb:off"

      # Force-probe the AMD motherboard output for the optional 3rd monitor.
      # Remove if unused; connector name confirmed via `ls /sys/class/drm/card1/`
      "video=card1-HDMI-A-2:e"

      # Disable nouveau completely
      "rd.driver.blacklist=nouveau"
      "modprobe.blacklist=nouveau"

      # Stability
      "nowatchdog"
      "mitigations=off"

      "loglevel=4"
      "lsm=landlock,yama,bpf"
    ];

    blacklistedKernelModules = ["nouveau"];
  };

  # ==================== DISPLAY / WAYLAND ====================
  # With reverseSync, AMD (card1) is the Wayland render device.
  # Hyprland must open card1 so PRIME-linked NVIDIA outputs are visible.
  environment.sessionVariables.WLR_DRM_DEVICES = "/dev/dri/card1";

  # Both drivers must be listed so X / KMS initialises them in the right order
  services.xserver.videoDrivers = ["amdgpu" "nvidia"];
}
