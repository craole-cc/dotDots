{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.zfs-root.Home.craole.templates.desktop;
  inherit (lib) mkDefault mkOption types mkIf;
in {
  options.zfs-root.Home.craole.templates.desktop = {
    enable = mkOption {
      description = "Enable system config template by craole";
      type = types.bool;
      default = false;
    };
  };
  config = mkIf cfg.enable {
    zfs-root = {
      boot = {
        devNodes = "/dev/disk/by-id/";
        #        immutable = true;
      };
      #      networking = {
      #        timeZone = "America/Jamaica";
      #        useDHCP = true;
      #        networkmanager.enable = true;
      #        #Home.craole.enable = true;i
      #      };
    };
    users.mutableUsers = false;
    home-manager.users.craole = {
      home = {
        username = "craole";
        homeDirectory = mkDefault "/home/craole";
        stateVersion = mkDefault "22.11";
      };
      programs = {
        home-manager.enable = true;
        #        sway.enable = true;
      };
    };
    users.users = {
      craole = {
        initialHashedPassword = "$6$JpGyTjd922XkFGCs$QTOrGXyAPjmMqKH6FlisS/mWDSQkOWYDU1iWVaH5oeoHA0FwjTeMvIuXwzz5WwF6O2o8hVDLstHhmyJftaZJ60";
        description = "Craig 'Craole' Cole";
        extraGroups = [
          "wheel"
          "libvirtd"
          "networkmanager"
          "dialout"
        ];
        #        openssh.authorizedKeys.keys = [
        #          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEeuanloGpRSuYbfJV3eGnfgyX1djaGC7UjUSgJeraKM openpgp:0x5862BCF8"
        #        ];
        packages = builtins.attrValues {
          inherit
            (pkgs)
            ffmpeg
            mg
            nixfmt
            qrencode
            minicom
            zathura
            jmtpfs
            gpxsee
            pdfcpu
            # image editor
            
            # pdf manipulation suite in C++
            
            # https://qpdf.readthedocs.io/en/stable/
            
            qpdf
            vscode
            alejandra
            ;
        };
        isNormalUser = true;
      };
    };
    hardware = {
      opengl = {
        extraPackages =
          builtins.attrValues {inherit (pkgs) vaapiIntel intel-media-driver;};
        enable = true;
      };
      bluetooth = {
        enable = true;
        powerOnBoot = true;
      };
      pulseaudio.enable = false;
    };
    services = {
      xserver = {
        enable = true;
        desktopManager.gnome.enable = true;
        displayManager.gdm.enable = true;
      };
      blueman.enable = true;
      logind = {
        extraConfig = ''
          HandlePowerKey=suspend
        '';
        lidSwitch = "suspend";
        lidSwitchDocked = "ignore";
        lidSwitchExternalPower = "suspend";
      };
      pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
      };
    };
    sound.enable = true;
    programs.sway = {
      extraSessionCommands = ''
        export MOZ_ENABLE_WAYLAND=1
        export QT_QPA_PLATFORM=wayland-egl
        export XCURSOR_THEME=Adwaita
        export _JAVA_AWT_WM_NONREPARENTING=1
      '';
      enable = true;
      extraPackages = builtins.attrValues {
        inherit
          (pkgs)
          swaylock
          swayidle
          foot
          gammastep
          brightnessctl
          fuzzel
          grim
          w3m
          gsettings-desktop-schemas
          pavucontrol
          waybar
          wl-clipboard
          ;
      };
      # must be enabled, or else many programs will crash
      wrapperFeatures.gtk = true;
    };
    xdg.portal = {
      enable = true;
      wlr.enable = true;
    };
    fonts.fontconfig.defaultFonts = {
      monospace = ["Source Code Pro"];
      sansSerif = ["Noto Sans Display"];
      serif = ["Noto Sans Display"];
    };
    fonts.fonts = builtins.attrValues {
      inherit (pkgs) noto-fonts noto-fonts-cjk-sans source-code-pro;
    };
    environment.sessionVariables = {
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
      QT_WAYLAND_FORCE_DPI = "physical";
    };
  };
}
