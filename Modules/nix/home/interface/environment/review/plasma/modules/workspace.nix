{
  # pkgs,
  config,
  ...
}: let
  wallpapers = config.home.homeDirectory + "/Pictures/Wallpapers";
in {
  workspace = {
    clickItemTo = "select";
    enableMiddleClickPaste = true;
    # lookAndFeel = "org.kde.breezedark.desktop";
    colorScheme = "Materia-Color";
    cursor = {
      theme = "material_light_cursors";
      size = 32;
    };
    iconTheme = "candy-icons";

    splashScreen = {
      theme = "a2n.kuro";
    };
    wallpaperBackground = {
      blur = true;
    };
    wallpaperFillMode = "stretch";
    wallpaperSlideShow = {
      path = wallpapers;
      interval = 500;
    };
  };
}
