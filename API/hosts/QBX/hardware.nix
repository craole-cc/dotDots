{
  config,
  pkgs,
  modulesPath,
  ...
}: {
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
        "nvidia"
        "nvidia_modeset"
        "nvidia_uvm"
        "nvidia_drm"
      ];
    };
    extraModulePackages = [];
    kernelModules = ["kvm-amd"];
    # kernelPackages = pkgs.linuxPackages_latest;
    # loader = {
    #   systemd-boot.enable = true;
    #   efi.canTouchEfiVariables = true;
    #   timeout = 1;
    # };

    kernelParams = [
      #? For NVIDIA - Early KMS
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
      "nvidia.NVreg_EnableS0ixPowerManagement=1"
      "nvidia.NVreg_TemporaryFilePath=/var/tmp"
      "nvidia_drm.modeset=1"
      "nvidia_drm.fbdev=1"

      #? For AMD GPU
      "amdgpu.modeset=1"

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
        ExecStart = "${pkgs.coreutils}/bin/sleep 5";
      };
    };
  };
  # ==================== SYSTEM PROGRAMS ====================
  # programs = {
  #   obs-studio = {
  #     enable = true;
  #     enableVirtualCamera = true;
  #   };
  # };
}
