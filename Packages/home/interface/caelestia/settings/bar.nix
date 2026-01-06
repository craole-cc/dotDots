{...}: {
  settings.bar = {
    persistent = true;
    showOnHover = true;
    dragThreshold = 20;

    scrollActions = {
      workspaces = true;
      volume = true;
      brightness = true;
    };

    popouts = {
      activeWindow = true;
      tray = true;
      statusIcons = true;
    };

    workspaces = {
      shown = 5;
      activeIndicator = true;
      occupiedBg = true;
      showWindows = true;
      showWindowsOnSpecialWorkspaces = true;
      activeTrail = false;
      perMonitorWorkspaces = true;
      label = "  ";
      occupiedLabel = "󰮯";
      activeLabel = "󰮯";
      capitalisation = "preserve";
      specialWorkspaceIcons = [];
    };

    tray = {
      background = false;
      recolour = true;
      compact = true;
      iconSubs = [];
    };

    status = {
      showAudio = true;
      showMicrophone = true;
      showKbLayout = false;
      showNetwork = true;
      showBluetooth = true;
      showBattery = true;
      showLockStatus = true;
    };

    clock = {
      showIcon = true;
    };

    sizes = {
      innerWidth = 40;
      windowPreviewSize = 400;
      trayMenuWidth = 300;
      batteryWidth = 250;
      networkWidth = 320;
    };

    entries = [
      {
        enabled = true;
        id = "logo";
      }
      {
        enabled = true;
        id = "workspaces";
      }
      {
        enabled = true;
        id = "spacer";
      }
      {
        enabled = true;
        id = "activeWindow";
      }
      {
        enabled = true;
        id = "spacer";
      }
      {
        enabled = true;
        id = "speakers";
      }
      {
        enabled = true;
        id = "microphone";
      }
      {
        enabled = true;
        id = "tray";
      }
      {
        enabled = true;
        id = "clock";
      }
      {
        enabled = true;
        id = "statusIcons";
      }
      {
        enabled = true;
        id = "power";
      }
    ];
  };
}
