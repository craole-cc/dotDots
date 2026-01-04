{
  desktopWidgets = {
    enabled = false;
    gridSnap = false;
    monitorWidgets = [];
  };

  hooks = {
    enabled = false;
    darkModeChange = "";
    wallpaperChange = "";
  };

  wallpaper = let
    wallpapers = "$HOME/Pictures/Wallpapers";
  in {
    directory = wallpapers;
    enableMultiMonitorDirectories = true;
    enabled = true;
    fillColor = "#000000";
    fillMode = "crop";
    hideWallpaperFilenames = false;
    monitorDirectories = [
      # TODO: Make this  dynamic
      {
        directory = wallpapers + "/9x16";
        name = "HDMI-A-2";
        wallpaper = "";
      }
      {
        directory = wallpapers + "/16x9";
        name = "HDMI-A-3";
        wallpaper = "";
      }
      {
        directory = wallpapers + "/16x10";
        name = "DP-3";
        wallpaper = "";
      }
    ];
    overviewEnabled = true;
    panelPosition = "follow_bar";
    randomEnabled = true;
    randomIntervalSec = 3600;
    recursiveSearch = true;
    setWallpaperOnAllMonitors = true;
    transitionDuration = 1500;
    transitionEdgeSmoothness = 0.05;
    transitionType = "random";
    useWallhaven = true;
    wallhavenApiKey = "";
    wallhavenCategories = "111";
    wallhavenOrder = "desc";
    wallhavenPurity = "100";
    wallhavenQuery = "";
    wallhavenRatios = "";
    wallhavenResolutionHeight = "";
    wallhavenResolutionMode = "atleast";
    wallhavenResolutionWidth = "";
    wallhavenSorting = "relevance";
    wallpaperChangeMode = "random";
  };
}
