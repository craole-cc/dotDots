{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with config.dots.lib.get.host;
with interface.desktop;
let
  inherit (config.dots.info.host) interface isMinimal;
  inherit (interface.desktop) server manager;

  packages = with pkgs; rec {
    wayland =
      if (server == "wayland") then
        [
          #| Notification
          mako
          swayosd

          eww
          swww
          fuzzel
          foot
          grim
          slurp
          wl-clipboard
          hyprshot
        ]
      else
        [ ];
    x11 =
      if (server == "x11") then
        [
          xclip
          xsel
          variety
          betterlockscreen
        ]
      else
        [ ];
    tui = [
      #| System Information
      btop
      neofetch
      procs
      hyperfine
      macchina
      neofetch
      cpufetch

      # | Help
      tealdeer
      # cod

      # | Code
      tokei
      kondo

      # | Network
      bandwhich
      speedtest-go

      # | Regex
      grex

      #| Utility
      brightnessctl
      jq
      lsd
      libsixel
      lsix
      bc
      fend

      #| Web
      wget
      curl
    ];
    gui =
      if (manager != null) then
        [
          #| Notification
          dunst
          libnotify

          #| Image Management
          feh
          flameshot
          imagemagick

          #| Utility
          qalculate-gtk
        ]
        ++ wayland
        ++ x11
      else
        [ ];
  };
in
{
  config = {
    environment = {
      systemPackages = with packages; tui ++ gui;
    };

    programs = {
      firefox.enable = !isMinimal;
      goldwarden.enable = !isMinimal;

      starship.enable = true;
      bandwhich.enable = true;
      light = {
        enable = true;
        brightnessKeys = {
          enable = true;
          step = 10;
        };
      };
    };

    services = {
      clight = {
        enable = true;
        temperature = {
          day = 6400;
          night = 3200;
        };
      };
      udisks2.enable = !isMinimal;
    };
  };
}
