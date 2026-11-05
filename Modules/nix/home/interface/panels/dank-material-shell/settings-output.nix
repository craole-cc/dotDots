{lix}: let
  inherit (lix.attrsets.construction) listToAttrs;
  inherit (lix.attrsets.transformation) mapAttrsToList;
  inherit (lix.lists.construction) concatLists;
  inherit (lix.strings.construction) concatStringsSep;
  inherit (lix.types.predicates) isAttrs isString;

  fields = {
    animation = {
      duration = "animationDuration";
      motion = "motionEffect";
    };
    applications = {
      substitutions = "appIdSubstitutions";
    };
    avatar = {
      ring = "avatarRing";
    };
    bars = {
      backups = "connectedFrameBarStyleBackups";
      configs = "barConfigs";
      padding = {
        shared = "barInsetPaddingShared";
        sync = "barInsetPaddingSyncAll";
      };
    };
    battery = {
      charge.limit = "batteryChargeLimit";
      notify = {
        charge.limit = "batteryNotifyChargeLimit";
        low = "batteryNotifyLow";
      };
      profile = "batteryProfileName";
      saver.auto = "batteryAutoPowerSaver";
    };
    blur = {
      border = {
        enable = "blurBorderEnabled";
        seeded = "blurBorderSeeded";
      };
      enable = "blurEnabled";
      foreground.layers = "blurForegroundLayers";
    };
    buttons.color.mode = "buttonColorMode";
    calendar.backend = "calendarBackend";
    clipboard = {
      filter.remember = "clipboardRememberTypeFilter";
      history = null;
      paste = {
        click = "clipboardClickToPaste";
        enter = "clipboardEnterToPaste";
      };
    };
    clock = {
      format = "clockFormat";
      seconds = "showSeconds";
      week.number = "showWeekNumber";
    };
    config.version = "configVersion";
    controls = {
      columns = "controlCenterColumns";
      tiles.color.mode = "controlCenterTileColorMode";
      widgets = "controlCenterWidgets";
    };
    corners.radius = "radiusStrength";
    cursor = "cursorSettings";
    displays = {
      preferred = "screenPreferences";
      profile.auto = "displayProfileAutoSelect";
    };
    dock.configs = "dockConfigs";
    focus = {
      ring = {
        enable = "focusRingEnabled";
        width = "focusRingWidth";
      };
    };
    fonts = {
      mono.family = "monoFontFamily";
      render = {
        quality = "textRenderQuality";
        type = "textRenderType";
      };
      sans.family = "fontFamily";
    };
    frame = {
      bar = {
        padding = "frameBarInsetPadding";
        size = "frameBarSize";
      };
      enable = "frameEnabled";
      launcher = {
        arc.extend = "frameLauncherArcExtender";
        edge.hover = "frameLauncherEdgeHover";
      };
      rounding = "frameRounding";
      thickness = "frameThickness";
    };
    greeter = {
      login.auto = "greeterAutoLogin";
      pam.external = "greeterPamExternallyManaged";
    };
    hyprland = {
      glow = {
        enable = "hyprlandGlowEnabled";
        power = "hyprlandGlowRenderPower";
        range = "hyprlandGlowRange";
      };
      groups.bar = {
        blur = "hyprlandGroupbarBlur";
        hide.single = "hyprlandGroupbarDisableWhenOnly";
        text.padding = "hyprlandGroupbarTextPadding";
      };
      layout = {
        border.size = "hyprlandLayoutBorderSize";
        dwindle.split = {
          preserve = "hyprlandDwindlePreserveSplit";
          smart = "hyprlandDwindleSmartSplit";
        };
        name = "hyprlandTilingLayout";
      };
      resize.border = "hyprlandResizeOnBorder";
      windows.opacity = "hyprlandWindowOpacity";
    };
    icons.theme = {
      adaptive = "iconThemePerMode";
      dark = "iconThemeDark";
      light = "iconThemeLight";
    };
    launcher = {
      border.enable = "dankLauncherV2BorderEnabled";
      drawer.sections = "appDrawerSectionViewModes";
      grid.columns = "appLauncherGridColumns";
      include = {
        files = "dankLauncherV2IncludeFilesInAll";
        folders = "dankLauncherV2IncludeFoldersInAll";
      };
      layer.overlay = "launcherUseOverlayLayer";
      spotlight.sections = "spotlightSectionViewModes";
      unload.close = "dankLauncherV2UnloadOnClose";
    };
    lock = {
      pam.external = "lockPamExternallyManaged";
      suspend = "lockBeforeSuspend";
    };
    network.preferred = "networkPreference";
    notifications = {
      compact = "notificationCompactMode";
      fonts = {
        body.size = "notificationBodyFontSize";
        summary.size = "notificationSummaryFontSize";
      };
      monitor.focused = "notificationFocusedMonitor";
      overlay.enable = "notificationOverlayEnabled";
      timeout.bar = "notificationShowTimeoutBar";
    };
    opacity = {
      floating = {
        background = "floatingWindowTransparency";
        foreground = "floatingWindowForegroundTransparency";
        layers = "floatingWindowForegroundLayers";
        sync = "floatingWindowSyncGlobal";
      };
      foreground = "foregroundLayerTransparency";
      popup = "popupTransparency";
    };
    osd = {
      media.enable = "osdMediaPlaybackEnabled";
      position = "osdPosition";
      power.profile.enable = "osdPowerProfileEnabled";
      value.always = "osdAlwaysShowValue";
      workspace.enable = "osdWorkspaceEnabled";
    };
    plugins = {
      builtin = "builtInPluginSettings";
    };
    power = {
      ac.lock.timeout = "acLockTimeout";
      battery.suspend.timeout = "batterySuspendTimeout";
      menu = {
        actions = "powerMenuActions";
        grid = "powerMenuGridLayout";
      };
    };
    scrolling = {
      bars.enable = "scrollbarsEnabled";
    };
    sounds = {
      enable = "soundsEnabled";
    };
    theme = {
      category = "currentThemeCategory";
      file = "customThemeFile";
      matugen = {
        contrast = "matugenContrast";
        scheme = "matugenScheme";
        templates = {
          enable = "runDmsMatugenTemplates";
          foot = "matugenTemplateFoot";
          ghostty = "matugenTemplateGhostty";
          gtk = "matugenTemplateGtk";
          vscode = "matugenTemplateVscode";
          zed = "matugenTemplateZed";
          zen = "matugenTemplateZenBrowser";
        };
      };
      name = "currentThemeName";
    };
    updates.check.start = "updaterCheckOnStart";
    wallpaper.fill = "wallpaperFillMode";
    widgets = {
      background.color = "widgetBackgroundColor";
      color.mode = "widgetColorMode";
    };
    windows = {
      centering = "centeringMode";
      floating.seeded = "dmsWindowsFloatingSeeded";
    };
  };

  encode = path: fields: values:
    if !isAttrs values
    then throw "DMS settings.${concatStringsSep "." path} must be an attribute set."
    else
      concatLists (mapAttrsToList (name: value:
        if !(fields ? ${name})
        then throw "Unknown DMS setting: settings.${concatStringsSep "." (path ++ [name])}"
        else if fields.${name} == null
        then []
        else if isString fields.${name}
        then [
          {
            name = fields.${name};
            inherit value;
          }
        ]
        else encode (path ++ [name]) fields.${name} value)
      values);
in
  settings: {
    settings = listToAttrs (encode [] fields settings);
    clipboardSettings = settings.clipboard.history or {};
  }
