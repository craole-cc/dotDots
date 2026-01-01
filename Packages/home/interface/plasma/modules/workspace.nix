{
  # pkgs,
  config,
  ...
}: let
  wallpapers = config.home.homeDirectory + "/Pictures/Wallpapers";
  # wallpapers = "/home/craole/.dots/Assets/Images/wallpaper";
  # wallpapers = "/home/craole/Pictures/Wallpapers";
  # pkgs.candy-icons
in {
  workspace = {
    clickItemTo = "open"; # If you liked the click-to-open default from plasma 5
    lookAndFeel = "org.kde.breezedark.desktop";
    cursor = {
      theme = "material_cursors";
      size = 32;
    };
    iconTheme = "candy-icons";
    # wallpaper = "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/Patak/contents/images/1080x1920.png";
    wallpaperBackground = {
      blur = true;
    };
    wallpaperFillMode = "preserveAspectFit";
    wallpaperSlideShow = {
      path = wallpapers;
      interval = 500;
    };
  };
}
