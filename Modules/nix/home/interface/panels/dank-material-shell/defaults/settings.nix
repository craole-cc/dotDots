{
  theme.name = "dynamic";
  theme.category = "dynamic";
  theme.matugen.scheme = "scheme-smart";
  theme.matugen.contrast = -0.35;
  opacity.popup = 0.75;
  opacity.floating.sync = false;
  opacity.floating.background = 0.75;
  opacity.floating.foreground = 0.85;
  widgets.background.color = "sc";
  widgets.color.mode = "colorful";
  controls.tiles.color.mode = "primary";
  buttons.color.mode = "primary";
  hyprland.layout.border.size = -1;
  hyprland.resize.border = false;
  clock.week.number = true;
  clock.format = "24h";
  clock.seconds = true;
  animation.motion = 2;
  blur.enable = true;
  opacity.foreground = 1;
  controls.widgets = [
    {
      "col" = 0;
      "enabled" = true;
      "h" = 1;
      "id" = "user";
      "row" = 0;
      "w" = 4;
    }
    {
      "col" = 4;
      "enabled" = true;
      "h" = 1;
      "id" = "settings";
      "row" = 0;
      "small" = true;
      "w" = 1;
    }
    {
      "col" = 5;
      "enabled" = true;
      "h" = 1;
      "id" = "power";
      "row" = 0;
      "small" = true;
      "w" = 1;
    }
    {
      "col" = 0;
      "enabled" = true;
      "h" = 1;
      "id" = "wifi";
      "row" = 2;
      "small" = true;
      "w" = 3;
    }
    {
      "col" = 0;
      "enabled" = true;
      "h" = 1;
      "id" = "bluetooth";
      "row" = 1;
      "small" = true;
      "w" = 3;
    }
    {
      "col" = 0;
      "enabled" = true;
      "h" = 1;
      "id" = "darkMode";
      "row" = 3;
      "small" = true;
      "w" = 1;
    }
    {
      "col" = 1;
      "enabled" = true;
      "h" = 1;
      "id" = "idleInhibitor";
      "row" = 4;
      "small" = true;
      "w" = 1;
    }
    {
      "col" = 3;
      "enabled" = true;
      "h" = 1;
      "id" = "builtin_tailscale";
      "row" = 3;
      "small" = true;
      "w" = 3;
    }
    {
      "col" = 3;
      "enabled" = true;
      "h" = 1;
      "id" = "plugin_dankKDEConnect";
      "row" = 4;
      "small" = true;
      "w" = 3;
    }
    {
      "col" = 2;
      "enabled" = true;
      "h" = 1;
      "id" = "doNotDisturb";
      "row" = 4;
      "small" = true;
      "w" = 1;
    }
    {
      "col" = 0;
      "enabled" = true;
      "h" = 1;
      "id" = "edit";
      "row" = 4;
      "small" = true;
      "w" = 1;
    }
    {
      "col" = 2;
      "enabled" = true;
      "h" = 1;
      "id" = "plugin_dmsScreenshot";
      "row" = 3;
      "small" = true;
      "w" = 1;
    }
    {
      "col" = 1;
      "enabled" = true;
      "h" = 1;
      "id" = "plugin_screenRecorder";
      "row" = 3;
      "small" = true;
      "w" = 1;
    }
    {
      "id" = "audioOutput";
      "enabled" = true;
      "w" = 3;
      "h" = 1;
      "col" = 3;
      "row" = 1;
      "small" = true;
    }
    {
      "id" = "audioInput";
      "enabled" = true;
      "w" = 3;
      "h" = 1;
      "col" = 3;
      "row" = 2;
      "small" = true;
    }
  ];
  applications.substitutions = [
    {
      "pattern" = "zen-";
      "replacement" = "zen";
      "type" = "contains";
    }
  ];
  windows.centering = "geometric";
  greeter.login.auto = true;
  greeter.pam.external = true;
  launcher.grid.columns = 3;
  launcher.spotlight.sections = {
    "apps" = "tile";
  };
  launcher.drawer.sections = {
    "apps" = "tile";
  };
  launcher.border.enable = true;
  launcher.unload.close = true;
  launcher.include.files = true;
  launcher.include.folders = true;
  launcher.layer.overlay = true;
  network.preferred = "wifi";
  icons.theme.dark = "System Default";
  icons.theme.light = "System Default";
  icons.theme.adaptive = true;
  cursor = {
    "theme" = "material_dark_cursors";
    "size" = 24;
    "niri" = {
      "hideWhenTyping" = false;
      "hideAfterInactiveMs" = 0;
    };
    "hyprland" = {
      "hideOnKeyPress" = true;
      "hideOnTouch" = true;
      "inactiveTimeout" = 2;
    };
    "dwl" = {
      "cursorHideTimeout" = 0;
    };
  };
  fonts.sans.family = "Sans Serif";
  fonts.mono.family = "Monospace";
  fonts.render.type = 1;
  fonts.render.quality = 4;
  notifications.fonts.summary.size = 12;
  notifications.fonts.body.size = 10;
  sounds.enable = false;
  power.ac.lock.timeout = 1800;
  power.battery.suspend.timeout = 900;
  battery.profile = "0";
  battery.charge.limit = 90;
  battery.notify.charge.limit = true;
  battery.notify.low = true;
  battery.saver.auto = true;
  lock.suspend = true;
  notifications.overlay.enable = true;
  lock.pam.external = true;
  notifications.compact = true;
  notifications.timeout.bar = true;
  notifications.monitor.focused = true;
  osd.value.always = true;
  osd.media.enable = true;
  osd.power.profile.enable = true;
  power.menu.actions = [
    "reboot"
    "logout"
    "poweroff"
    "lock"
    "suspend"
    "restart"
    "softreboot"
    "switchuser"
    "hibernate"
  ];
  power.menu.grid = true;
  updates.check.start = true;
  displays.preferred = {
    "wallpaper" = ["all"];
  };
  displays.profile.auto = true;
  bars.backups = {
    "default" = {
      "shadowIntensity" = 0;
      "squareCorners" = true;
      "attachToScreenEdge" = false;
      "gothCornersEnabled" = false;
      "borderEnabled" = false;
    };
    "bar1789057563774" = {
      "shadowIntensity" = 0;
      "squareCorners" = true;
      "attachToScreenEdge" = false;
      "gothCornersEnabled" = false;
      "borderEnabled" = false;
    };
    "bar1789058160987" = {
      "shadowIntensity" = 0;
      "squareCorners" = true;
      "attachToScreenEdge" = false;
      "gothCornersEnabled" = false;
      "borderEnabled" = false;
    };
    "bar1789058162218" = {
      "shadowIntensity" = 0;
      "squareCorners" = true;
      "attachToScreenEdge" = false;
      "gothCornersEnabled" = false;
      "borderEnabled" = false;
    };
  };
  bars.configs = [
    {
      "id" = "default";
      "name" = "Main Bar";
      "enabled" = true;
      "position" = 0;
      "screenPreferences" = [
        "all"
      ];
      "showOnLastDisplay" = true;
      "leftWidgets" = [
        {
          "id" = "focusedWindow";
          "enabled" = true;
          "focusedWindowCompactMode" = false;
          "focusedWindowSize" = 1;
        }
        {
          "id" = "workspaceSwitcher";
          "enabled" = true;
          "showWorkspaceApps" = true;
          "maxWorkspaceIcons" = 2;
          "workspaceAppIconSizeOffset" = 1;
          "groupActiveWorkspaceApps" = true;
          "workspaceFollowFocus" = true;
          "showOccupiedWorkspacesOnly" = true;
          "reverseScrolling" = true;
          "workspaceColorMode" = "primaryContainer";
          "workspaceUnfocusedColorMode" = "s";
        }
      ];
      "centerWidgets" = [
        {
          "id" = "music";
          "enabled" = true;
        }
        {
          "id" = "clock";
          "enabled" = true;
        }
        {
          "id" = "weather";
          "enabled" = true;
        }
      ];
      "rightWidgets" = [
        {
          "id" = "capsLockIndicator";
          "enabled" = true;
        }
        {
          "id" = "privacyIndicator";
          "enabled" = true;
        }
        {
          "id" = "developerUtilities";
          "enabled" = false;
        }
        {
          "id" = "systemTray";
          "enabled" = true;
          "trayAutoOverflow" = false;
          "trayIconSpacing" = 2;
          "trayUseInlineExpansion" = false;
          "trayMaxVisibleItems" = 0;
        }
        {
          "id" = "colorPicker";
          "enabled" = false;
        }
        {
          "id" = "clipboard";
          "enabled" = true;
        }
        {
          "id" = "notificationButton";
          "enabled" = true;
        }
        {
          "id" = "controlCenterButton";
          "enabled" = true;
          "showNetworkIcon" = true;
          "showBluetoothIcon" = true;
          "showAudioIcon" = true;
          "showAudioPercent" = false;
          "showVpnIcon" = true;
          "showBrightnessIcon" = false;
          "showBrightnessPercent" = false;
          "showMicIcon" = false;
          "showMicPercent" = true;
          "showBatteryIcon" = false;
          "showPrinterIcon" = false;
          "showScreenSharingIcon" = true;
          "showIdleInhibitorIcon" = false;
          "showDoNotDisturbIcon" = false;
          "controlCenterGroupOrder" = [
            "network"
            "vpn"
            "bluetooth"
            "audio"
            "microphone"
            "brightness"
            "battery"
            "printer"
            "screenSharing"
            "idleInhibitor"
            "doNotDisturb"
          ];
        }
      ];
      "spacing" = 0;
      "innerPadding" = -8;
      "bottomGap" = 0;
      "transparency" = 1;
      "widgetTransparency" = 1;
      "squareCorners" = false;
      "noBackground" = true;
      "maximiseWidgetIcons" = true;
      "maximiseWidgetText" = true;
      "widgetPadding" = 8;
      "gothCornersEnabled" = false;
      "gothCornerRadiusOverride" = true;
      "gothCornerRadiusValue" = 32;
      "borderEnabled" = false;
      "borderColor" = "surfaceText";
      "borderOpacity" = 0.25;
      "borderThickness" = 1;
      "widgetOutlineEnabled" = false;
      "widgetOutlineColor" = "surfaceText";
      "widgetOutlineOpacity" = 0.28;
      "widgetOutlineThickness" = 1;
      "fontScale" = 0.75;
      "iconScale" = 1;
      "autoHide" = false;
      "autoHideDelay" = 250;
      "showOnWindowsOpen" = true;
      "openOnOverview" = false;
      "visible" = true;
      "popupGapsAuto" = true;
      "popupGapsManual" = 4;
      "maximizeDetection" = true;
      "scrollEnabled" = true;
      "scrollXBehavior" = "focusWindow";
      "scrollYBehavior" = "workspace";
      "shadowIntensity" = 0;
      "shadowOpacity" = 60;
      "shadowColorMode" = "text";
      "shadowCustomColor" = "#000000";
      "clickThrough" = false;
      "useOverlayLayer" = false;
      "autoHideStrict" = true;
      "hoverPopouts" = true;
      "islandHomeCompactTight" = false;
      "islandCornerRadius" = 34;
      "islandHighContrast" = false;
      "islandNotificationExpand" = true;
      "islandNotificationBadgeClearOnOpen" = true;
      "islandSatelliteBackground" = false;
      "attachToScreenEdge" = false;
      "followInterfaceStyle" = true;
      "widgetFollowInterfaceStyle" = false;
      "clickActionFollowMouse" = true;
      "middleClickAction" = "spotlight";
    }
    {
      "id" = "bar1789057563774";
      "name" = "Bar 2";
      "enabled" = false;
      "position" = 3;
      "screenPreferences" = [
        "all"
      ];
      "showOnLastDisplay" = false;
      "leftWidgets" = [];
      "centerWidgets" = [
        {
          "id" = "battery";
          "enabled" = true;
        }
        {
          "id" = "cpuUsage";
          "enabled" = true;
          "minimumWidth" = true;
        }
        {
          "id" = "cpuTemp";
          "enabled" = true;
          "minimumWidth" = true;
        }
        {
          "id" = "memUsage";
          "enabled" = true;
          "minimumWidth" = true;
          "showInGb" = false;
        }
        {
          "id" = "diskUsage";
          "enabled" = true;
          "mountPath" = "/";
          "diskUsageMode" = 0;
          "showMountPath" = true;
          "minimumWidth" = true;
        }
        {
          "id" = "network_speed_monitor";
          "enabled" = true;
        }
        {
          "id" = "nixMonitor";
          "enabled" = true;
        }
      ];
      "rightWidgets" = [];
      "spacing" = 0;
      "innerPadding" = -8;
      "bottomGap" = 0;
      "transparency" = 1;
      "widgetTransparency" = 1;
      "squareCorners" = false;
      "noBackground" = true;
      "gothCornersEnabled" = false;
      "gothCornerRadiusOverride" = true;
      "gothCornerRadiusValue" = 32;
      "borderEnabled" = false;
      "borderColor" = "surfaceText";
      "borderOpacity" = 0.25;
      "borderThickness" = 1;
      "widgetOutlineEnabled" = false;
      "widgetOutlineColor" = "primary";
      "widgetOutlineOpacity" = 1;
      "widgetOutlineThickness" = 1;
      "widgetPadding" = 8;
      "maximiseWidgetIcons" = true;
      "maximiseWidgetText" = true;
      "fontScale" = 0.75;
      "iconScale" = 1;
      "autoHide" = true;
      "autoHideStrict" = true;
      "autoHideDelay" = 250;
      "showOnWindowsOpen" = true;
      "openOnOverview" = false;
      "visible" = true;
      "popupGapsAuto" = true;
      "popupGapsManual" = 4;
      "maximizeDetection" = true;
      "useOverlayLayer" = false;
      "scrollEnabled" = true;
      "scrollXBehavior" = "focusWindow";
      "scrollYBehavior" = "workspace";
      "hoverPopouts" = true;
      "hoverPopoutDelay" = 150;
      "shadowIntensity" = 0;
      "shadowOpacity" = 60;
      "shadowDirectionMode" = "inherit";
      "shadowDirection" = "top";
      "shadowColorMode" = "text";
      "shadowCustomColor" = "#000000";
      "attachToScreenEdge" = false;
      "followInterfaceStyle" = false;
      "widgetFollowInterfaceStyle" = false;
    }
    {
      "id" = "bar1789058160987";
      "name" = "Bar 3";
      "enabled" = false;
      "position" = 1;
      "screenPreferences" = [
        "all"
      ];
      "showOnLastDisplay" = false;
      "leftWidgets" = [
        {
          "id" = "music";
          "enabled" = true;
        }
      ];
      "centerWidgets" = [];
      "rightWidgets" = [
        {
          "id" = "capsLockIndicator";
          "enabled" = false;
        }
        {
          "id" = "privacyIndicator";
          "enabled" = false;
        }
        {
          "id" = "notificationButton";
          "enabled" = false;
        }
        {
          "id" = "systemTray";
          "enabled" = false;
          "trayAutoOverflow" = false;
        }
        {
          "id" = "notepadButton";
          "enabled" = false;
        }
        {
          "id" = "wallpaperDiscovery";
          "enabled" = false;
        }
        {
          "id" = "screenRecorder";
          "enabled" = true;
        }
        {
          "id" = "clipboard";
          "enabled" = true;
        }
        {
          "id" = "showDesktop";
          "enabled" = true;
        }
      ];
      "spacing" = 0;
      "innerPadding" = -8;
      "bottomGap" = 0;
      "transparency" = 1;
      "widgetTransparency" = 1;
      "squareCorners" = false;
      "noBackground" = true;
      "gothCornersEnabled" = false;
      "gothCornerRadiusOverride" = true;
      "gothCornerRadiusValue" = 32;
      "borderEnabled" = false;
      "borderColor" = "surfaceText";
      "borderOpacity" = 0.25;
      "borderThickness" = 1;
      "widgetOutlineEnabled" = false;
      "widgetOutlineColor" = "primary";
      "widgetOutlineOpacity" = 1;
      "widgetOutlineThickness" = 1;
      "widgetPadding" = 8;
      "maximiseWidgetIcons" = true;
      "maximiseWidgetText" = true;
      "fontScale" = 0.75;
      "iconScale" = 1;
      "autoHide" = true;
      "autoHideStrict" = true;
      "autoHideDelay" = 250;
      "showOnWindowsOpen" = true;
      "openOnOverview" = false;
      "visible" = true;
      "popupGapsAuto" = true;
      "popupGapsManual" = 4;
      "maximizeDetection" = true;
      "useOverlayLayer" = false;
      "scrollEnabled" = true;
      "scrollXBehavior" = "focusWindow";
      "scrollYBehavior" = "workspace";
      "hoverPopouts" = true;
      "hoverPopoutDelay" = 150;
      "shadowIntensity" = 0;
      "shadowOpacity" = 60;
      "shadowDirectionMode" = "inherit";
      "shadowDirection" = "top";
      "shadowColorMode" = "text";
      "shadowCustomColor" = "#000000";
      "attachToScreenEdge" = false;
      "followInterfaceStyle" = false;
      "widgetFollowInterfaceStyle" = false;
    }
    {
      "id" = "bar1789058162218";
      "name" = "Bar 4";
      "enabled" = true;
      "position" = 2;
      "screenPreferences" = [
        "all"
      ];
      "showOnLastDisplay" = false;
      "leftWidgets" = [];
      "centerWidgets" = [
        {
          "id" = "clock";
          "enabled" = false;
        }
        {
          "id" = "weather";
          "enabled" = false;
        }
        {
          "id" = "battery";
          "enabled" = true;
          "showBatteryPercent" = true;
          "showBatteryPercentOnlyOnBattery" = false;
          "showBatteryTime" = false;
          "showBatteryTimeOnlyOnBattery" = false;
          "batteryPillPercentSign" = false;
        }
        {
          "id" = "cpuUsage";
          "enabled" = true;
          "minimumWidth" = true;
        }
        {
          "id" = "cpuTemp";
          "enabled" = true;
          "minimumWidth" = true;
        }
        {
          "id" = "memUsage";
          "enabled" = true;
          "minimumWidth" = true;
          "showInGb" = false;
        }
        {
          "id" = "diskUsage";
          "enabled" = true;
          "mountPath" = "/";
          "diskUsageMode" = 0;
          "showMountPath" = true;
          "minimumWidth" = true;
        }
        {
          "id" = "network_speed_monitor";
          "enabled" = true;
        }
        {
          "id" = "nixMonitor";
          "enabled" = true;
        }
      ];
      "rightWidgets" = [
        {
          "id" = "wallpaperDiscovery";
          "enabled" = false;
        }
        {
          "id" = "colorPicker";
          "enabled" = true;
        }
        {
          "id" = "developerUtilities";
          "enabled" = false;
        }
        {
          "id" = "notepadButton";
          "enabled" = false;
        }
      ];
      "spacing" = 0;
      "innerPadding" = -8;
      "bottomGap" = 0;
      "transparency" = 1;
      "widgetTransparency" = 1;
      "squareCorners" = false;
      "noBackground" = true;
      "gothCornersEnabled" = false;
      "gothCornerRadiusOverride" = true;
      "gothCornerRadiusValue" = 32;
      "borderEnabled" = false;
      "borderColor" = "surfaceText";
      "borderOpacity" = 0.25;
      "borderThickness" = 1;
      "widgetOutlineEnabled" = false;
      "widgetOutlineColor" = "primary";
      "widgetOutlineOpacity" = 1;
      "widgetOutlineThickness" = 1;
      "widgetPadding" = 8;
      "maximiseWidgetIcons" = true;
      "maximiseWidgetText" = true;
      "fontScale" = 0.75;
      "iconScale" = 1;
      "autoHide" = false;
      "autoHideStrict" = true;
      "autoHideDelay" = 250;
      "showOnWindowsOpen" = true;
      "openOnOverview" = false;
      "visible" = true;
      "popupGapsAuto" = true;
      "popupGapsManual" = 4;
      "maximizeDetection" = true;
      "useOverlayLayer" = false;
      "scrollEnabled" = true;
      "scrollXBehavior" = "focusWindow";
      "scrollYBehavior" = "workspace";
      "hoverPopouts" = true;
      "hoverPopoutDelay" = 150;
      "shadowIntensity" = 0;
      "shadowOpacity" = 60;
      "shadowDirectionMode" = "inherit";
      "shadowDirection" = "top";
      "shadowColorMode" = "text";
      "shadowCustomColor" = "#000000";
      "islandFloating" = false;
      "attachToScreenEdge" = false;
      "followInterfaceStyle" = true;
      "widgetFollowInterfaceStyle" = false;
    }
  ];
  plugins.builtin = {
    "dms_settings_search" = {
      "trigger" = "?";
    };
    "dms_clipboard_search" = {
      "trigger" = "cb";
    };
    "dms_power" = {
      "trigger" = "pw";
    };
    "dms_qr_generator" = {
      "trigger" = "qrg";
    };
  };
  clipboard.paste.click = true;
  clipboard.paste.enter = true;
  clipboard.filter.remember = true;
  frame.enable = true;
  frame.thickness = 2;
  frame.rounding = 0;
  frame.bar.size = 24;
  frame.launcher.arc.extend = true;
  frame.launcher.edge.hover = true;
  bars.padding.shared = 0;
  bars.padding.sync = true;
  frame.bar.padding = 2;
  config.version = 42;
  theme.matugen.templates.enable = true;
  theme.matugen.templates.gtk = true;
  theme.matugen.templates.ghostty = true;
  theme.matugen.templates.foot = true;
  corners.radius = 0;
  animation.duration = 200;
  blur.border.enable = false;
  dock.configs = [
    {
      "id" = "dock";
      "name" = "Dock";
      "enabled" = true;
      "screenPreferences" = [
        "all"
      ];
      "showOnLastDisplay" = true;
      "position" = 1;
      "mode" = "compact";
      "taskbarAlign" = "center";
      "widgetExpansion" = "popout";
      "iconSize" = 42;
      "spacing" = 8;
      "itemSpacing" = 8;
      "margin" = 0;
      "bottomGap" = 0;
      "transparency" = 1;
      "followInterfaceStyle" = true;
      "autoHide" = false;
      "smartAutoHide" = true;
      "useOverlayLayer" = true;
      "editOnRightClick" = false;
      "showOnFullscreen" = true;
      "openOnOverview" = false;
      "groupByApp" = true;
      "separatePinnedAndRunningApps" = false;
      "restoreSpecialWorkspaceOnClick" = true;
      "isolateDisplays" = false;
      "indicatorStyle" = "circle";
      "borderEnabled" = false;
      "borderColor" = "surfaceText";
      "borderOpacity" = 1;
      "borderThickness" = 3;
      "launcherEnabled" = true;
      "launcherLogoMode" = "os";
      "launcherLogoCustomPath" = "";
      "launcherLogoColorOverride" = "";
      "launcherLogoSizeOffset" = 0;
      "launcherLogoBrightness" = 0.5;
      "launcherLogoContrast" = 1;
      "maxVisibleApps" = 0;
      "maxVisibleRunningApps" = 0;
      "showOverflowBadge" = true;
      "showTrash" = true;
      "trashFileManager" = "default";
      "trashCustomCommand" = "";
      "magnification" = false;
      "magnificationScale" = 130;
      "magnificationProfile" = "parabolic";
      "magnificationExpand" = false;
      "order" = [];
      "widgets" = [
        {
          "enabled" = true;
          "id" = "dock_launcher";
          "widgetId" = "dockLauncher";
        }
        {
          "enabled" = true;
          "id" = "dock_apps";
          "widgetId" = "appsDock";
        }
        {
          "enabled" = true;
          "id" = "dock_trash";
          "widgetId" = "dockTrash";
        }
      ];
    }
  ];
  blur.border.seeded = true;
  windows.floating.seeded = [
    "hyprland"
  ];
  blur.foreground.layers = false;
  focus.ring.enable = false;
  focus.ring.width = 1.5;
  scrolling.bars.enable = false;
  hyprland.layout.name = "dwindle";
  hyprland.layout.dwindle.split.smart = true;
  hyprland.layout.dwindle.split.preserve = false;
  opacity.floating.layers = true;
  wallpaper.fill = "Fill";
  hyprland.windows.opacity = 96;
  hyprland.groups.bar.hide.single = true;
  hyprland.groups.bar.blur = true;
  hyprland.glow.enable = true;
  hyprland.glow.range = 4;
  hyprland.glow.power = 3;
  hyprland.groups.bar.text.padding = 0;
  avatar.ring = "primary";
  controls.columns = 6;
  osd.position = 6;
  osd.workspace.enable = true;
  clipboard.history = import ./clipboard.nix;
}
