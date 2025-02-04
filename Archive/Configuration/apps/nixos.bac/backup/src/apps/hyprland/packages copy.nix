{ config, pkgs, ... }:
{
  config = {
    home-manager.users.craole = {

      wayland.windowManager.hyprland.enable = true;

      home.packages = with pkgs; [
        #| Notifiers
        dunst
        libnotify
        mako

        eww
        swww

        #| Terminal
        foot
        kitty

        #| Launchers
        anyrun
        fuzzel
        wofi
        walker

        #| Screenshot Utilities
        grim
        slurp
        wl-clipboard
        hyprshot

        #| Misc
        jq
      ];

      xdg.portal = {
        enable = true;
        config.common.default = "*";
        extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
      };
    };
  };
}
