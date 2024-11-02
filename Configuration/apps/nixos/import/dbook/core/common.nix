{
  config,
  pkgs,
  ...
}: let
  inherit (config.DOTS) alpha stateVersion location;
in {
  environment.variables.ALPHA = config.DOTS.alpha;
  system = {inherit stateVersion;};
  time = {inherit (location) timeZone;};
  i18n = {inherit (location) defaultLocale;};
  location = {
    inherit (location) longitude latitude;
    provider = let
      inherit (config.location) latitude longitude;
    in
      if (latitude == null || longitude == null)
      then "geoclue2"
      else "manual";
  };

  users.users."${alpha}" = {
    isNormalUser = true;
    description = alpha;
    extraGroups = ["networkmanager" "wheel"];
  };

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 3d";
    };
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      system-features = [
        "big-parallel"
        "kvm"
        "recursive-nix"
        "nixos-test"
      ];
    };
  };

  security = {
    pam.services.gdm.enableGnomeKeyring = true;
    rtkit.enable = true;
    sudo = {
      execWheelOnly = true;
      extraRules = [
        {
          users = [alpha];
          commands = [
            {
              command = "ALL";
              options = ["SETENV" "NOPASSWD"];
            }
          ];
        }
      ];
    };
  };

  services = {
    displayManager = {
      autoLogin = {
        enable = true;
        user = alpha;
      };
    };

    gnome = {gnome-keyring.enable = true;};
    blueman.enable = true;

    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
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

    tailscale.enable = true;
  };

  programs = {
    git = {
      enable = true;
      lfs.enable = true;
    };
    direnv = {
      enable = true;
      silent = true;
    };
    # dconf.enable = true;
    # gnupg.agent = {
    #   enable = true;
    #   enableSSHSupport = true;
    # };
  };

  environment.systemPackages = with pkgs; [
    #| System Information
    btop
    neofetch
    procs
    hyperfine
    macchina
    neofetch
    cpufetch

    #| Help
    tealdeer
    # cod

    #| Development
    helix
    nixd
    nixfmt-rfc-style
    alejandra
    nil
    vscode-fhs
    tokei
    kondo
    shellcheck
    shfmt
    treefmt2
    warp-terminal
    wezterm

    # | Network
    bandwhich
    speedtest-go

    #| Utility
    bat
    ripgrep
    fd
    brightnessctl
    jq
    lsd
    libsixel
    lsix
    bc
    grex
    pavucontrol
    qalculate-gtk
    fend
    easyeffects
    qjackctl

    #| Web
    brave
    wget
    curl
    freetube
  ];
}
