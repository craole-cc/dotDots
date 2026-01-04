{
  host,
  monitors,
  ...
}: {
  calendar = {
    cards = [
      {
        enabled = true;
        id = "calendar-header-card";
      }
      {
        enabled = true;
        id = "calendar-month-card";
      }
      {
        enabled = true;
        id = "timer-card";
      }
      {
        enabled = true;
        id = "weather-card";
      }
    ];
  };

  location = {
    analogClockInCalendar = false;
    firstDayOfWeek = -1;
    name = host.localization.city or "Mandeville, Jamaica";
    showCalendarEvents = true;
    showCalendarWeather = true;
    showWeekNumberInCalendar = false;
    use12hourFormat = true;
    useFahrenheit = false;
    weatherEnabled = true;
    weatherShowEffects = true;
  };

  notifications = {
    backgroundOpacity = 1;
    criticalUrgencyDuration = 15;
    enableKeyboardLayoutToast = true;
    enabled = true;
    location = "top_right";
    lowUrgencyDuration = 3;
    monitors = [monitors.primaryName];
    normalUrgencyDuration = 8;
    overlayLayer = true;
    respectExpireTimeout = false;
    saveToHistory = {
      critical = true;
      low = true;
      normal = true;
    };
    sounds = {
      criticalSoundFile = "";
      enabled = false;
      excludedApps = ["discord" "firefox" "chrome" "chromium" "edge"];
      lowSoundFile = "";
      normalSoundFile = "";
      separateSounds = false;
      volume = 0.5;
    };
  };

  osd = {
    autoHideMs = 2000;
    enabled = true;
    enabledTypes = [
      0
      1
      2
      4
      3
    ];
    "location" = "top_right";
    monitors = [monitors.primaryName];
    overlayLayer = true;
  };

  systemMonitor = {
    cpuCriticalThreshold = 90;
    cpuPollingInterval = 3000;
    cpuWarningThreshold = 80;
    criticalColor = "";
    diskCriticalThreshold = 90;
    diskPath = "/";
    diskPollingInterval = 3000;
    diskWarningThreshold = 80;
    enableDgpuMonitoring = false;
    externalMonitor = "resources || missioncenter || jdsystemmonitor || corestats || system-monitoring-center || gnome-system-monitor || plasma-systemmonitor || mate-system-monitor || ukui-system-monitor || deepin-system-monitor || pantheon-system-monitor";
    gpuCriticalThreshold = 90;
    gpuPollingInterval = 3000;
    gpuWarningThreshold = 80;
    memCriticalThreshold = 90;
    memPollingInterval = 3000;
    memWarningThreshold = 80;
    networkPollingInterval = 3000;
    tempCriticalThreshold = 90;
    tempPollingInterval = 3000;
    tempWarningThreshold = 80;
    useCustomColors = false;
    warningColor = "";
  };
}
