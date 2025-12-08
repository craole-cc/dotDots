{
  enable,
  pkgs,
  mkIf,
  ...
}: {
  config = mkIf enable {
    programs = {
      hyprland = {
        enable = true;
        withUWSM = true;
      };

      # kitty.enable = true;
    };

    environment.systemPackages = with pkgs; [
      kitty
      #     dunst
      #     libnotify
      #     mako
      #     eww
      #     swww
      #     # rofi-wayland
      #     bemenu
      #     wofi
      #     fuzzel
      #     foot
      #     # tofi

      #     jq
      #     grim
      #     slurp
      #     wl-clipboard
      #     hyprshot
    ];
  };
}
