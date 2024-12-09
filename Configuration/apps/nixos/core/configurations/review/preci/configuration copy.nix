{ config, lib, ... }:
{
  # TODO: get via options
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ehci_pci"
        "ahci"
        "usb_storage"
        "sd_mod"
        "sr_mod"
        "sdhci_pci"
      ];
      kernelModules = [ ];
      luks.devices = {
        "luks-d6bafe54-e55b-49b8-ab7c-18380939f56f" = {
          device = "/dev/disk/by-uuid/d6bafe54-e55b-49b8-ab7c-18380939f56f";
        };
        "luks-540965a0-c573-42f9-8d14-2ae37c3715e6" = {
          device = "/dev/disk/by-uuid/540965a0-c573-42f9-8d14-2ae37c3715e6";
        };
      };
    };
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelModules = [ "kvm-intel" ];
    kernelPackages = pkgs.linuxPackages_latest; # TODO: get via options
    extraModulePackages = [ ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/5fe83d0f-15a3-4abf-abb2-2ba02cc9195d";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/542E-33C1";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/d1aa80d2-ba1f-412f-9d81-5c5f5c6a839d"; }
  ];

  # TODO: get via options
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };

  networking = {
    hostName = "preci";
    networkmanager.enable = true;
    interfaces = {
      eno1.useDHCP = lib.mkDefault true;
      wlp3s0.useDHCP = lib.mkDefault true;
    };

    firewall = {
      enable = false;
      # allowedTCPPorts = [ ... ];
      # allowedUDPPorts = [ ... ];
    };
  };

  # TODO: get via options
  nixpkgs = {
    config.allowUnfree = lib.mkDefault true;
    hostPlatform = lib.mkDefault "x86_64-linux";
  };

  # TODO: get via options
  hardware = {
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    pulseaudio.enable = lib.mkDefault false;
    bluetooth = {
      enable = lib.mkDefault true;
      settings.General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };
  };

  system = {
    stateVersion = "24.05";
  };

  time = {
    timeZone = lib.mkDefault "America/Jamaica";
    hardwareClockInLocalTime = lib.mkDefault true;
  };

  location = {
    latitude = 18.015;
    longitude = 77.49;
    provider = "manual";
  };

  i18n = {
    defaultLocale = lib.mkDefault "en_US.UTF-8";
  };

  #TODO: get via options
  security = {
    sudo = {
      execWheelOnly = true;
      extraRules = [
        {
          users = [ "craole" ];
          commands = [
            {
              command = "ALL";
              options = [
                "SETENV"
                "NOPASSWD"
              ];
            }
          ];
        }
      ];
    };
    rtkit.enable = true;
  };

  #TODO: get via options
  console = {
    packages = [ pkgs.terminus_font ];
    font = "ter-u32n";
    earlySetup = true;
    useXkbConfig = true;
  };

  #TODO: get via options
  services = {
    displayManager = {
      autoLogin = {
        enable = true;
        user = "craole";
      };
      sddm = {
        enable = true;
        wayland.enable = true;
      };
    };

    desktopManager = {
      plasma6.enable = true;
      # gnone.enable = true;
    };

    kmscon = {
      enable = true;
      autologinUser = "craole";
    };

    upower = {
      enable = true;
    };

    redshift = {
      enable = true;
      brightness = {
        day = "1";
        night = "0.75";
      };
      temperature = {
        day = 5500;
        night = 3800;
      };
    };

    blueman = {
      enable = true;
    };

    libinput = {
      enable = true;
    };

    tailscale = {
      enable = true;
    };

    ollama = {
      enable = true;
      loadModels = [
        "mistral-nemo"
        # "yi-coder:9b"
      ];
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      extraConfig.pipewire."92-low-latency" = {
        context.properties.default.clock = {
          rate = 48000;
          quantum = 32;
          min-quantum = 32;
          max-quantum = 32;
        };
      };
    };
  };

  programs = {
    hyprland.enable = true;
    hyprlock.enable = true;
  };

  environment = {
    systemPackages = with pkgs; [
      helix
      nil
      nixd
      nixfmt-rfc-style
      btop
      dust
      speedtest-go
      nix-info
      bat
      brave
      pavucontrol
      easyeffects
      qjackctl
      brightnessctl
      sutils
    ];
    variables = {
      FLAKE_PATH = "${flakePath}";
      FLAKE_DIR = toString flakePath;
      FLAKE_RAW = flakePath;
      FLAKE_FILE = (lib.filesystem.locateDominatingFile "flake.nix" ./.).path;
      FLAKE = "$HOME/.dots";
      EDITOR = "hx";
      VISUAL = "zeditor";
      BROWSER = "brave";
      PAGER = "bat --paging=always";
      MANPAGER = "bat --paging=always --plain";
      LESS = "-R";
      # LESS_ADVANCED_PREPROCESSOR = "1";
      # LESS_TERMCAP_mb = "$(printf '\e[1;31m')";
      # LESS_TERMCAP_md = "$(printf '\e[1;36m')";
      # LESS_TERMCAP_me = "$(printf '\e[0m')";
      # LESS_TERMCAP_se = "$(printf '\e[0m')";
      # LESS_TERMCAP_so = "$(printf '\e[01;33m')";
      # LESS_TERMCAP_ue = "$(printf '\e[0m')";
      # LESS_TERMCAP_us = "$(printf '\e[1;32m')";
      # LESSCHARSET = "UTF-8";
      COLORTERM = "truecolor";
      TERM = "xterm-256color";
    };
    shellAliases = {
      h = "history";
      # la = "eza --group-directories-first --git --almost-all  --smart-group --absolute";
      # ll = "la --long";
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "....." = "cd ../../../..";
      x = "exit";
    };
  };

  fonts = {
    packages = with pkgs; [
      (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    ];
  };

  users.users = {
    craole = {
      isNormalUser = true;
      description = "Craole";
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
      packages = with pkgs; [
        zed-editor
        vscode-fhs
        warp-terminal
      ];
    };
  };
}
