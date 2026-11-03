{lix}: let
  inherit (lix.attrsets.construction) listToAttrs;
  inherit (lix.attrsets.transformation) mapAttrsToList;
  inherit (lix.lists.construction) concatLists;
  inherit (lix.strings.construction) concatStringsSep;
  inherit (lix.types.predicates) isAttrs isString;

  fields = {
    animation.duration = "animationDuration";
    animation.motion = "motionEffect";
    applications.substitutions = "appIdSubstitutions";
    avatar.ring = "avatarRing";
    bars.backups = "connectedFrameBarStyleBackups";
    bars.configs = "barConfigs";
    bars.padding.shared = "barInsetPaddingShared";
    bars.padding.sync = "barInsetPaddingSyncAll";
    battery.charge.limit = "batteryChargeLimit";
    battery.notify.charge.limit = "batteryNotifyChargeLimit";
    battery.notify.low = "batteryNotifyLow";
    battery.profile = "batteryProfileName";
    battery.saver.auto = "batteryAutoPowerSaver";
    blur.border.enable = "blurBorderEnabled";
    blur.border.seeded = "blurBorderSeeded";
    blur.enable = "blurEnabled";
    blur.foreground.layers = "blurForegroundLayers";
    buttons.color.mode = "buttonColorMode";
    calendar.backend = "calendarBackend";
    clipboard.filter.remember = "clipboardRememberTypeFilter";
    clipboard.paste.click = "clipboardClickToPaste";
    clipboard.paste.enter = "clipboardEnterToPaste";
    clock.format = "clockFormat";
    clock.seconds = "showSeconds";
    clock.week.number = "showWeekNumber";
    config.version = "configVersion";
    controls.columns = "controlCenterColumns";
    controls.tiles.color.mode = "controlCenterTileColorMode";
    controls.widgets = "controlCenterWidgets";
    corners.radius = "radiusStrength";
    cursor = "cursorSettings";
    displays.preferred = "screenPreferences";
    displays.profile.auto = "displayProfileAutoSelect";
    dock.configs = "dockConfigs";
    focus.ring.enable = "focusRingEnabled";
    focus.ring.width = "focusRingWidth";
    fonts.mono.family = "monoFontFamily";
    fonts.render.quality = "textRenderQuality";
    fonts.render.type = "textRenderType";
    fonts.sans.family = "fontFamily";
    frame.bar.padding = "frameBarInsetPadding";
    frame.bar.size = "frameBarSize";
    frame.enable = "frameEnabled";
    frame.launcher.arc.extend = "frameLauncherArcExtender";
    frame.launcher.edge.hover = "frameLauncherEdgeHover";
    frame.rounding = "frameRounding";
    frame.thickness = "frameThickness";
    greeter.login.auto = "greeterAutoLogin";
    greeter.pam.external = "greeterPamExternallyManaged";
    hyprland.glow.enable = "hyprlandGlowEnabled";
    hyprland.glow.power = "hyprlandGlowRenderPower";
    hyprland.glow.range = "hyprlandGlowRange";
    hyprland.groups.bar.blur = "hyprlandGroupbarBlur";
    hyprland.groups.bar.hide.single = "hyprlandGroupbarDisableWhenOnly";
    hyprland.groups.bar.text.padding = "hyprlandGroupbarTextPadding";
    hyprland.layout.border.size = "hyprlandLayoutBorderSize";
    hyprland.layout.dwindle.split.preserve = "hyprlandDwindlePreserveSplit";
    hyprland.layout.dwindle.split.smart = "hyprlandDwindleSmartSplit";
    hyprland.layout.name = "hyprlandTilingLayout";
    hyprland.resize.border = "hyprlandResizeOnBorder";
    hyprland.windows.opacity = "hyprlandWindowOpacity";
    icons.theme.adaptive = "iconThemePerMode";
    icons.theme.dark = "iconThemeDark";
    icons.theme.light = "iconThemeLight";
    launcher.border.enable = "dankLauncherV2BorderEnabled";
    launcher.drawer.sections = "appDrawerSectionViewModes";
    launcher.grid.columns = "appLauncherGridColumns";
    launcher.include.files = "dankLauncherV2IncludeFilesInAll";
    launcher.include.folders = "dankLauncherV2IncludeFoldersInAll";
    launcher.layer.overlay = "launcherUseOverlayLayer";
    launcher.spotlight.sections = "spotlightSectionViewModes";
    launcher.unload.close = "dankLauncherV2UnloadOnClose";
    lock.pam.external = "lockPamExternallyManaged";
    lock.suspend = "lockBeforeSuspend";
    network.preferred = "networkPreference";
    notifications.compact = "notificationCompactMode";
    notifications.fonts.body.size = "notificationBodyFontSize";
    notifications.fonts.summary.size = "notificationSummaryFontSize";
    notifications.monitor.focused = "notificationFocusedMonitor";
    notifications.overlay.enable = "notificationOverlayEnabled";
    notifications.timeout.bar = "notificationShowTimeoutBar";
    opacity.floating.background = "floatingWindowTransparency";
    opacity.floating.foreground = "floatingWindowForegroundTransparency";
    opacity.floating.layers = "floatingWindowForegroundLayers";
    opacity.floating.sync = "floatingWindowSyncGlobal";
    opacity.foreground = "foregroundLayerTransparency";
    opacity.popup = "popupTransparency";
    osd.media.enable = "osdMediaPlaybackEnabled";
    osd.position = "osdPosition";
    osd.power.profile.enable = "osdPowerProfileEnabled";
    osd.value.always = "osdAlwaysShowValue";
    osd.workspace.enable = "osdWorkspaceEnabled";
    plugins.builtin = "builtInPluginSettings";
    power.ac.lock.timeout = "acLockTimeout";
    power.battery.suspend.timeout = "batterySuspendTimeout";
    power.menu.actions = "powerMenuActions";
    power.menu.grid = "powerMenuGridLayout";
    scrolling.bars.enable = "scrollbarsEnabled";
    sounds.enable = "soundsEnabled";
    theme.category = "currentThemeCategory";
    theme.file = "customThemeFile";
    theme.matugen.contrast = "matugenContrast";
    theme.matugen.scheme = "matugenScheme";
    theme.matugen.templates.enable = "runDmsMatugenTemplates";
    theme.matugen.templates.foot = "matugenTemplateFoot";
    theme.matugen.templates.ghostty = "matugenTemplateGhostty";
    theme.matugen.templates.gtk = "matugenTemplateGtk";
    theme.matugen.templates.vscode = "matugenTemplateVscode";
    theme.matugen.templates.zed = "matugenTemplateZed";
    theme.matugen.templates.zen = "matugenTemplateZenBrowser";
    theme.name = "currentThemeName";
    updates.check.start = "updaterCheckOnStart";
    wallpaper.fill = "wallpaperFillMode";
    widgets.background.color = "widgetBackgroundColor";
    widgets.color.mode = "widgetColorMode";
    windows.centering = "centeringMode";
    windows.floating.seeded = "dmsWindowsFloatingSeeded";
    clipboard.history = null;
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
