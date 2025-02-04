{ config, pkgs, ... }:
{
  config = {
    home-manager.users.craole = {

      wayland.windowManager.hyprland.enable = true;

      home.packages = with pkgs; [
        dunst
        libnotify
        mako
        eww
        swww
        # rofi-wayland
        bemenu
        wofi
        fuzzel
        foot
        # tofi

        jq
        grim
        slurp
        wl-clipboard
        hyprshot
      ];

      xdg.portal = {
        enable = true;
        config.common.default = "*";
        extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
      };
    };
  };
}
