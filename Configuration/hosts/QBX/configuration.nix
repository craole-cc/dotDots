{
  inputs ? null,
  pkgs,
  modulesPath,
  ...
}:
let
  alpha = {
    username = "craole";
    description = "Craig 'Craole' Cole";
    git = {
      name = "craole-cc";
      email = "134658831+craole-cc@users.noreply.github.com";
    };
  };

  getGitHub =
    {
      owner,
      repo,
      rev,
      sha256,
    }:
    builtins.fetchTarball {
      url = "https://github.com/${owner}/${repo}/archive/${rev}.tar.gz";
      inherit sha256;
    };

  resolvedInputs =
    if inputs != null then
      inputs
    else
      {
        nixosCore = getGitHub {
          owner = "NixOS";
          repo = "nixpkgs";
          rev = "f61125a668a320878494449750330ca58b78c557";
          sha256 = "sha256-BmPWzogsG2GsXZtlT+MTcAWeDK5hkbGRZTeZNW42fwA=";
        };

        nixosHome = getGitHub {
          owner = "nix-community";
          repo = "home-manager";
          rev = "e5b1f87841810fc24772bf4389f9793702000c9b";
          sha256 = "sha256-BVVyAodLcAD8KOtR3yCStBHSE0WAH/xQWH9f0qsxbmk=";
        };
      };

  stateVersion = "25.11";
  hwModules = modulesPath + "/installer/scan/not-detected.nix";
  homeModules = import "${resolvedInputs.nixosHome}/nixos";

in
with alpha;
{
  nix = {
    nixPath = [
      "nixpkgs=${inputs.nixosCore}"
      "nixos-config=/etc/nixos/configuration.nix"
    ];
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };

  nixpkgs = {
    hostPlatform = "x86_64-linux";
    config.allowUnfree = true;
  };

  imports = [
    hwModules
    homeModules
  ];

  hardware = {
    cpu.amd.updateMicrocode = true;

    enableAllFirmware = true;
    amdgpu.initrd.enable = true;

    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;

      prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        amdgpuBusId = "PCI:12:0:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };

    graphics.enable = true;

    bluetooth = {
      enable = true;
      settings.General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };
  };

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
      kernelModules = [ ];
    };
    extraModulePackages = [ ];
    kernelModules = [ "kvm-amd" ];
    # kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      timeout = 1;
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/1f5ca117-cd68-439b-8414-b3b39bc28d75";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/C6C0-2B64";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };

  networking = {
    hostName = "qbx";
    networkmanager.enable = true;
  };

  location = {
    longitude = "18.015";
    latitude = "77.49";
    provider = "manual";
  };

  time = {
    timeZone = "America/Jamaica";
    hardwareClockInLocalTime = true;
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
  };

  system = {
    inherit stateVersion;
    copySystemConfiguration = inputs == null;
  };

  services = {
    displayManager.sddm.enable = true;
    desktopManager.plasma6.enable = true;

    openssh.enable = true;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };

    printing.enable = true;
    pulseaudio.enable = false;

    qbittorrent = {
      enable = true;
      openFirewall = true;
    };
  };

  security = {
    rtkit.enable = true;
    sudo = {
      execWheelOnly = true;
      extraRules = [
        {
          users = [ username ];
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
  };

  programs = {
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

  users.users."${username}" = {
    inherit description;
    isNormalUser = true;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };

  home-manager = {
    backupFileExtension = "backup";
    overwriteBackup = true;
    useGlobalPkgs = true;
    useUserPackages = true;
    # extraSpecialArgs = {};
    # sharedModules = [];
    users."${username}" = {
      fonts.fontconfig = {
        enable = true;
        hinting = "slight";
        antialiasing = true;
        subpixelRendering = "rgb";
        defaultFonts = {
          emoji = [ "Noto Color Emoji" ];
          monospace = [
            "Maple Mono NF"
            "Monaspace Radon"
            "VictorMono Nerd Font"
          ];
          serif = [ "Noto Serif" ];
          sansSerif = [ "Noto Sans" ];
        };
      };

      home = {
        inherit stateVersion;
        packages = with pkgs; [
          maple-mono.NF
          monaspace
          victor-mono
          warp-terminal
        ];
        sessionVariables = {
          # EDITOR = "hx";
          VISUAL = "code";
        };
      };

      programs = {
        bat = {
          enable = true;
        };

        firefox = {
          enable = true;
        };

        git = {
          enable = true;
          lfs.enable = true;
          settings = {
            user = { inherit (git) name email; };
            core = {
              whitespace = "trailing-space,space-before-tab";
            };
            init = {
              defaultBranch = "main";
            };
            url = {
              "https://github.com/" = {
                insteadOf = [
                  "gh:"
                  "github:"
                ];
              };
            };
          };
        };
        gitui.enable = true;
        gh = {
          enable = true;
        };
        jujutsu = {
          enable = true;
          settings.user = { inherit (git) name email; };
        };
        delta = {
          enable = true;
          enableGitIntegration = true;
          enableJujutsuIntegration = true;
        };

        ripgrep-all.enable = true;

        fd.enable = true;

        topgrade = {
          enable = true;
          settings = {
            misc = {
              assume_yes = true;
              disable = [
                "flutter"
                "node"
              ];
              set_title = false;
              cleanup = true;
            };
            commands = {
              "Run garbage collection on Nix store" = "nix-collect-garbage";
            };
          };
        };
        # oh-my-posh={
        #   enable=true;
        #   enableBashIntegration = true;
        #   enableNushellIntegration = true;
        # };
        starship = {
          enable = true;
        };
        helix = {
          enable = true;
          defaultEditor = true;
        };
        vscode = {
          enable = true;
          package = pkgs.vscode-fhs;
        };
      };
    };
  };

  environment = {
    systemPackages = with pkgs; [
      helix
      nil
      nixd
      nixfmt
      alejandra
      direnv
      rust-script
      gcc
      ripgrep
      toybox
      mesa-demos
    ];
    # pathsToLink = [
    #   "/share/xdg-desktop-portal"
    #   "/share/applications"
    # ];
    sessionVariables = {
      # EDITOR = "hx";
      # VISUAL = "code";

      #? For Clutter/GTK apps
      CLUTTER_BACKEND = "wayland";

      #? For GTK apps
      GDK_BACKEND = "wayland";

      #? Required for Java UI apps on Wayland
      _JAVA_AWT_WM_NONREPARENTING = "1";

      #? Enable Firefox native Wayland backend
      MOZ_ENABLE_WAYLAND = "1";

      #? Force Chromium/Electron apps to use Wayland
      NIXOS_OZONE_WL = "1";

      #? Qt apps use Wayland
      QT_QPA_PLATFORM = "wayland";

      #? Disable client-side decorations for Qt apps
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";

      #? Auto scale for HiDPI displays
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";

      #? SDL2 apps Wayland backend
      SDL_VIDEODRIVER = "wayland";

      #? Allow software rendering fallback on Nvidia/VM
      WLR_RENDERER_ALLOW_SOFTWARE = "1";

      #? Disable hardware cursors on Nvidia/VM
      WLR_NO_HARDWARE_CURSORS = "1";

      #? Indicate Wayland session to apps
      XDG_SESSION_TYPE = "wayland";
    };
  };
}
