{
  enable,
  pkgs,
  mkIf,
  ...
}: {
  config = mkIf enable {
    programs.niri = {
      enable = true;
    };

    environment = {
      systemPackages = with pkgs; [
        kitty
        dunst
        libnotify
        # mako
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
    };
    # xdg.portal = {
    #   enable = true;
    #   config.common.default = "*";
    #   extraPortals = with pkgs; [xdg-desktop-portal-gtk];
    # };
  };
}
