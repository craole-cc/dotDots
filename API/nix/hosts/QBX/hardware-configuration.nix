{
  config,
  pkgs,
  modulesPath,
  lib,
  ...
}:
let
  inherit (lib.modules) mkDefault;
in
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # ==================== HARDWARE ====================
  hardware = {
    cpu.amd.updateMicrocode = true;
    enableAllFirmware = true;
    amdgpu.initrd.enable = true;
    graphics.enable = true;
    nvidia = {
      open = false;
      package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
      forceFullCompositionPipeline = true;
      modesetting.enable = true;
      powerManagement.enable = false;
      nvidiaPersistenced = false;
      nvidiaSettings = false;

      prime = {
        amdgpuBusId = "PCI:12:0:0"; # 0c:00.0 AMD Granite Ridge
        nvidiaBusId = "PCI:1:0:0"; # 01:00.0 GTX 1050 Ti
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        reverseSync.enable = false;
        sync.enable = false;
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
    extraModulePackages = [ ];
    extraModprobeConfig = "options nvidia_drm modeset=1 fbdev=1";

    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
      kernelModules = [
        "amdgpu"
        "kvm-amd"
      ];
    };

    loader = {
      systemd-boot.enable = mkDefault true;
      efi.canTouchEfiVariables = mkDefault true;
      timeout = mkDefault 5;
    };

    kernelParams = [
      #~@ NVIDIA registry options
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
      "nvidia.NVreg_EnableS0ixPowerManagement=1"
      "nvidia.NVreg_TemporaryFilePath=/var/tmp"

      #~@ AMD
      "amdgpu.modeset=1"
      "amd_pstate=active"

      #? simpledrm is built into the NixOS kernel — it cannot be blacklisted.
      #? These params prevent it from binding to the EFI framebuffer device,
      #? leaving the NVIDIA PCI slot free for nvidia_drm to claim at stage-2.
      "video=efifb:off"
      "video=vesa:off"
      "video=simplefb:off"

      # Force-probe AMD mobo port for optional 3rd monitor (card1-HDMI-A-2
      # confirmed connected in hyprctl output).
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

    # nouveau only — simpledrm is built-in and ignores this list
    blacklistedKernelModules = [ "nouveau" ];
  };

  # ==================== DISPLAY / WAYLAND ====================
  # AMD (card1) is the Wayland render node under reverseSync.
  # NVIDIA-connected monitors appear as PRIME outputs on card1.
  environment.sessionVariables.WLR_DRM_DEVICES = "/dev/dri/card1";

  # amdgpu first sets the init order — AMD registers before NVIDIA.
  services.xserver.videoDrivers = [
    "amdgpu"
    "nvidia"
  ];
}
