{
  config,
  pkgs,
  modulesPath,
  lib,
  ...
}: let
  inherit (lib.modules) mkDefault;
  sleep = "${pkgs.coreutils}/bin/sleep";
in {
  # ==================== IMPORTS ====================
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];
  # ==================== HARDWARE ====================
  hardware = {
    #~@ CPU
    cpu.amd.updateMicrocode = true;
    enableAllFirmware = true;
    amdgpu.initrd.enable = true;

    #~@ GPU
    graphics.enable = true;
    nvidia = {
      open = false;
      package = config.boot.kernelPackages.nvidiaPackages.production;
      forceFullCompositionPipeline = true;
      modesetting.enable = true;
      powerManagement.enable = false;
    };

    #~@ Bluetooth
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
      kernelModules = [
        "amdgpu"
        "kvm-amd"
        "nvidia"
        "nvidia_drm"
        "nvidia_modeset"
        "nvidia_uvm"
      ];
    };
    loader = {
      systemd-boot.enable = mkDefault true;
      efi.canTouchEfiVariables = mkDefault true;
      timeout = mkDefault 5;
    };

    kernelParams = [
      #? For NVIDIA - Early KMS
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
      "nvidia.NVreg_EnableS0ixPowerManagement=1"
      "nvidia.NVreg_TemporaryFilePath=/var/tmp"
      "nvidia_drm.modeset=1"
      "nvidia_drm.fbdev=1"

      #? For AMD GPU
      "amdgpu.modeset=1"

      #? For AMD CPU
      "amd_pstate=active"

      #? Blacklist nouveau
      "rd.driver.blacklist=nouveau"
      "modprobe.blacklist=nouveau"

      #? General stability
      "nowatchdog"
      "mitigations=off"

      #? Force probe NVIDIA outputs (card0 - the discrete GPU)
      "video=card0-DP-3:e"
      "video=card0-HDMI-A-3:e"

      #? Force probe AMD output (card1 - the motherboard/integrated)
      "video=card1-HDMI-A-2:e"
    ];

    blacklistedKernelModules = ["nouveau"];
  };
  # ==================== SERVICES ====================
  services.xserver.videoDrivers = ["nvidia"];

  systemd.services = {
    "nvidia-wait-for-displays" = {
      description = "Wait for NVIDIA and AMD displays to initialize";
      wantedBy = ["display-manager.service"];
      before = ["display-manager.service"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${sleep} 3";
      };
    };
  };
}
