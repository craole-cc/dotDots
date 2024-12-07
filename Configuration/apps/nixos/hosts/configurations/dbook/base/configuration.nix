{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
let
  plasmaEnabled = config.services.desktopManager.plasma6.enable;
  sddmEnabled = config.services.displayManager.sddm.enable;
  xserverEnabled = config.services.xserver.enable;
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
      ];
      trusted-users = [
        "root"
        "craole"
        "@wheel"
      ];
    };
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

  console = {
    packages = [ pkgs.terminus_font ];
    font = "ter-u32n";
    earlySetup = true;
    useXkbConfig = true;
  };

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
    };

    kmscon = {
      enable = true;
      autologinUser = "craole";
    };

    blueman = {
      enable = true;
    };

    udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="hidraw", GROUP="users", MODE="0660", TAG+="uaccess"
    '';

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

    libinput = {
      enable = true;
    };

    tailscale = {
      enable = true;
    };

    # ollama = {
    #   enable = true;
    #   loadModels = [
    #     "mistral-nemo"
    #     # "yi-coder:9b"
    #   ];
    # };

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

  security = {
    pam.services = {
      login = {
        enableKwallet = plasmaEnabled;
        # forceRun = true;
      };
      sddm = {
        enableKwallet = plasmaEnabled && sddmEnabled;
        # forceRun = true;
      };
    };
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

  programs = {
    hyprland.enable = true;
    hyprlock.enable = true;
    git = {
      enable = true;
      lfs.enable = true;
    };
    direnv = {
      enable = true;
      silent = true;
    };
  };

  environment = {
    systemPackages =
      with pkgs;
      [
        #| Core Utilities
        usbutils
        uutils-coreutils-noprefix
        busybox
        bat
        fzf
        ripgrep
        sd
        tldr
        fd
        jq
        nix-prefetch-scripts
        nix-prefetch
        nix-prefetch-github
        nix-prefetch-docker

        #| Development
        nil
        nixd
        nixfmt-rfc-style
        nix-info
        shellcheck
        shfmt

        #| Filesystem
        dust
        eza

        #| System
        easyeffects
        pavucontrol
        qjackctl
        brightnessctl

        #| Utilities
        speedtest-go
        fend
        libqalculate
      ]
      ++ (
        if plasmaEnabled then
          [ kde-gruvbox ]
          ++ (with kdePackages; [
            # full
            koi
            kalm
            yakuake
          ])
        else
          [ ]
      )
      ++ (
        if xserverEnabled then
          [
            wmctrl
            xprop
            xdotool
            xinput
            xrandr
            qalculate-gtk
          ]
        else
          [ qalculate-qt ]
      );
    plasma6.excludePackages = with pkgs; [ kate ];
  };
}
