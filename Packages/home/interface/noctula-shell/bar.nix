{monitors, ...}: {
  bar = {
    backgroundOpacity = 0.11;
    capsuleOpacity = 1;
    density = "default";
    exclusive = true;
    floating = false;
    marginHorizontal = 1;
    marginVertical = 0.06;
    monitors = [monitors.all];
    outerCorners = true;
    position = "top";
    showCapsule = false;
    showOutline = false;
    useSeparateOpacity = false;
    widgets = {
      center = [
        # {
        #   characterCount = 2;
        #   colorizeIcons = false;
        #   enableScrollWheel = true;
        #   followFocusedScreen = false;
        #   groupedBorderOpacity = 1;
        #   hideUnoccupied = false;
        #   iconScale = 0.8;
        #   id = "Workspace";
        #   labelMode = "index";
        #   showApplications = true;
        #   showLabelsOnlyWhenOccupied = true;
        #   unfocusedIconsOpacity = 1;
        # }
      ];
      left = [
        # {
        #   hideMode = "alwaysExpanded";
        #   icon = "rocket";
        #   id = "CustomButton";
        #   leftClickExec = "qs -c noctalia-shell ipc call launcher toggle";
        #   leftClickUpdateText = false;
        #   maxTextLength = {
        #     horizontal = 10;
        #     vertical = 10;
        #   };
        #   middleClickExec = "";
        #   middleClickUpdateText = false;
        #   parseJson = false;
        #   rightClickExec = "";
        #   rightClickUpdateText = false;
        #   showIcon = true;
        #   textCollapse = "";
        #   textCommand = "";
        #   textIntervalMs = 3000;
        #   textStream = false;
        #   wheelDownExec = "";
        #   wheelDownUpdateText = false;
        #   wheelExec = "";
        #   wheelMode = "unified";
        #   wheelUpExec = "";
        #   wheelUpUpdateText = false;
        #   wheelUpdateText = false;
        # }
        # {
        #   customFont = "";
        #   formatHorizontal = "HH:mm ddd; MMM dd";
        #   formatVertical = "HH mm - dd MM";
        #   id = "Clock";
        #   tooltipFormat = "HH:mm ddd; MMM dd";
        #   useCustomFont = false;
        #   usePrimaryColor = false;
        # }
        # {
        #   compactMode = true;
        #   diskPath = "/";
        #   id = "SystemMonitor";
        #   showCpuTemp = true;
        #   showCpuUsage = true;
        #   showDiskUsage = true;
        #   showGpuTemp = true;
        #   showMemoryAsPercent = true;
        #   showMemoryUsage = true;
        #   showNetworkStats = true;
        #   useMonospaceFont = true;
        #   usePrimaryColor = true;
        # }
        # {
        #   colorizeIcons = false;
        #   hideMode = "hidden";
        #   id = "ActiveWindow";
        #   maxWidth = 640;
        #   scrollingMode = "hover";
        #   showIcon = true;
        #   useFixedWidth = false;
        # }
        # {
        #   hideMode = "hidden";
        #   hideWhenIdle = false;
        #   id = "MediaMini";
        #   maxWidth = 145;
        #   scrollingMode = "hover";
        #   showAlbumArt = true;
        #   showArtistFirst = true;
        #   showProgressRing = true;
        #   showVisualizer = true;
        #   useFixedWidth = true;
        #   visualizerType = "linear";
        # }
      ];
      right = [
        # {id = "ScreenRecorder";}
        # {
        #   blacklist = [];
        #   colorizeIcons = false;
        #   drawerEnabled = true;
        #   hidePassive = false;
        #   id = "Tray";
        #   pinned = [];
        # }
        # {
        #   hideWhenZero = false;
        #   id = "NotificationHistory";
        #   showUnreadBadge = true;
        # }
        # {
        #   deviceNativePath = "";
        #   displayMode = "onhover";
        #   hideIfNotDetected = true;
        #   id = "Battery";
        #   showNoctaliaPerformance = false;
        #   showPowerProfiles = false;
        #   warningThreshold = 30;
        # }
        # {
        #   displayMode = "onhover";
        #   id = "Volume";
        # }
        # {
        #   displayMode = "onhover";
        #   id = "Brightness";
        # }
        # {
        #   colorizeDistroLogo = false;
        #   colorizeSystemIcon = "none";
        #   customIconPath = "";
        #   enableColorization = false;
        #   icon = "noctalia";
        #   id = "ControlCenter";
        #   useDistroLogo = false;
        # }
      ];
    };
  };
}
