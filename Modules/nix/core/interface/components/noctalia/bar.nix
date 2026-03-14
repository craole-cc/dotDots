{monitors, ...}: {
  bar = {
    backgroundOpacity = 0.95;
    density = "default";
    exclusive = true;
    floating = false;
    marginHorizontal = 1;
    marginVertical = 0.06;
    monitors = [monitors.all];
    outerCorners = false;
    position = "top";
    showCapsule = false;
    capsuleOpacity = 0;
    showOutline = false;
    useSeparateOpacity = false;
    widgets = {
      left = [
        {
          id = "Workspace";
          labelMode = "index";
          characterCount = 2;
          colorizeIcons = true;
          enableScrollWheel = true;
          followFocusedScreen = true;
          groupedBorderOpacity = 1;
          hideUnoccupied = false;
          iconScale = 0.8;
          showApplications = true;
          showLabelsOnlyWhenOccupied = true;
          unfocusedIconsOpacity = .9;
        }
        {
          hideMode = "alwaysExpanded";
          icon = "rocket";
          id = "CustomButton";
          leftClickExec = "qs -c noctalia-shell ipc call launcher toggle";
          leftClickUpdateText = false;
          maxTextLength = {
            horizontal = 10;
            vertical = 10;
          };
          middleClickExec = "";
          middleClickUpdateText = false;
          parseJson = false;
          rightClickExec = "";
          rightClickUpdateText = false;
          showIcon = true;
          textCollapse = "";
          textCommand = "";
          textIntervalMs = 3000;
          textStream = false;
          wheelDownExec = "";
          wheelDownUpdateText = false;
          wheelExec = "";
          wheelMode = "unified";
          wheelUpExec = "";
          wheelUpUpdateText = false;
          wheelUpdateText = false;
        }
        {
          id = "ActiveWindow";
          colorizeIcons = false;
          hideMode = "hidden";
          maxWidth = 640;
          scrollingMode = "hover";
          showIcon = true;
          useFixedWidth = false;
        }
      ];
      center = [
        {
          customFont = "";
          formatHorizontal = "HH:mm ddd; MMM dd";
          formatVertical = "HH mm - dd MM";
          id = "Clock";
          tooltipFormat = "HH:mm ddd; MMM dd";
          useCustomFont = false;
          usePrimaryColor = false;
        }
        {
          id = "MediaMini";
          hideMode = "hidden";
          hideWhenIdle = false;
          maxWidth = 145;
          scrollingMode = "hover";
          showAlbumArt = true;
          showArtistFirst = true;
          showProgressRing = true;
          showVisualizer = true;
          useFixedWidth = true;
          visualizerType = "linear";
        }
      ];
      right = [
        {
          id = "Tray";
          blacklist = [];
          colorizeIcons = false;
          drawerEnabled = true;
          hidePassive = false;
          pinned = [];
        }
        {
          id = "SystemMonitor";
          compactMode = true;
          diskPath = "/";
          showCpuTemp = true;
          showCpuUsage = true;
          showDiskUsage = true;
          showGpuTemp = true;
          showMemoryAsPercent = true;
          showMemoryUsage = true;
          showNetworkStats = true;
          useMonospaceFont = true;
          usePrimaryColor = true;
        }
        {id = "ScreenRecorder";}
        {
          hideWhenZero = false;
          id = "NotificationHistory";
          showUnreadBadge = true;
        }
        {
          deviceNativePath = "";
          displayMode = "onhover";
          hideIfNotDetected = true;
          id = "Battery";
          showNoctaliaPerformance = false;
          showPowerProfiles = false;
          warningThreshold = 30;
        }
        {
          displayMode = "onhover";
          id = "Volume";
        }
        {
          displayMode = "onhover";
          id = "Brightness";
        }
        {
          colorizeDistroLogo = false;
          colorizeSystemIcon = "none";
          customIconPath = "";
          enableColorization = false;
          icon = "noctalia";
          id = "ControlCenter";
          useDistroLogo = true;
        }
      ];
    };
  };
}
