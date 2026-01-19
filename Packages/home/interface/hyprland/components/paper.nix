{wallpapers, ...}: {
  hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;
      splash_offset = 2.0;

      preload = ["/share/wallpapers/buttons.png" "/share/wallpapers/cat_pacman.png"];
      wallpaper = [
        "eDP-1,${wallpapers.eDP-1}"
        #   "DP-3,/share/wallpapers/buttons.png"
        #   "eDP-1,/share/wallpapers/cat_pacman.png"
      ];
    };
  };
}
