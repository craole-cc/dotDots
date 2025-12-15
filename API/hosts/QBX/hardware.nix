{
  config,
  pkgs,
  modulesPath,
  lib,
}: let
  # ==================== PATH ====================
  paths = let
    dots = "/home/${user.name}/.dots";
  in {
    inherit dots;
    base = dots + "/Configuration/hosts/QBX";
    orig = "/etc/nixos";
  };

  aliases = {
    se = "sudo hx --config \"/home/${user.name}/.config/helix/config.toml\"";
    nxe = "$EDITOR ${paths.base}";
    nxv = "$VISUAL ${paths.base}";
    nxs = "switch";
    nxu = "switch; topgrade";
    ll = "lsd --long --git --almost-all";
    lt = "lsd --tree";
    lr = "lsd --long --git --recursive";
  };
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
  programs = {
    git = {
      enable = true;
      lfs.enable = true;
      prompt.enable = true;
    };

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    obs-studio = {
      enable = true;
      enableVirtualCamera = true;
    };

    xwayland.enable = true;
  };

  # ==================== ENVIRONMENT ====================
  environment = {
    shellAliases = aliases;
    systemPackages = with pkgs; [
      #~@ Custom script
      (writeShellScriptBin "switch" ''
        set -euo pipefail

        if [ -d "${paths.base}" ]; then
          if [ -w "${paths.base}" ]; then
            gitui --directory "${paths.base}"
          else
            printf \
              "Config base %s is not writable as %s; fix permissions instead of using sudo.\n" \
              "${paths.base}" "$(whoami)"
            exit 1
          fi
        else
          printf "Invalid config base: %s\n" "${paths.base}"
          exit 1
        fi

        printf "🔍 Dry-run + trace on %s...\n" "${paths.base}"
        if sudo nixos-rebuild dry-run --show-trace; then
          printf "✅ Dry-run passed! Switching...\n"
          sudo nixos-rebuild switch
          printf "🎉 Switch complete + auto-backup triggered\n"
        else
          printf "❌ Dry-run failed - aborting\n"
          exit 1
        fi
      '')

      (writeShellScriptBin "wait-for-displays" ''
        set -euo pipefail

        max_attempts=10
        attempt=0

        while [ $attempt -lt $max_attempts ]; do
          # Check if all expected displays are detected
          if [ -e /sys/class/drm/card0-DP-3 ] && \
            [ -e /sys/class/drm/card0-HDMI-A-3 ] && \
            [ -e /sys/class/drm/card1-HDMI-A-2 ]; then
            printf "All displays detected\n"
            exit 0
          fi

          printf "Waiting for displays... attempt %s\n" "$attempt"
          sleep 0.5
          attempt=$((attempt + 1))
        done

        printf "Not all displays detected, continuing anyway\n"
        exit 0
      '')
    ];
  };
}
