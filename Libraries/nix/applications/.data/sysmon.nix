_: {
  htop = {
    names = {
      package = "htop";
      command = "htop";
      title = "htop";
    };
    exec = "htop";
    needsTerminal = true;
    categories = [
      "monitor"
      "process"
      "system"
    ];
  };

  btop = {
    names = {
      package = "btop";
      command = "btop";
      title = "btop";
    };
    exec = "btop";
    needsTerminal = true;
    categories = [
      "monitor"
      "process"
      "system"
    ];
  };

  nvtop = {
    names = {
      package = "nvtop";
      command = "nvtop";
      title = "nvtop";
    };
    exec = "nvtop";
    needsTerminal = true;
    categories = [
      "monitor"
      "process"
      "system"
    ];
  };

  mission-center = {
    names = {
      package = "mission-center";
      command = "missioncenter";
      class = "io.missioncenter.MissionCenter";
    };
    exec = "missioncenter";
    categories = [
      "monitor"
      "process"
      "system"
    ];
  };

  gnome-system-monitor = {
    family = "gnome";
    names = {
      package = "gnome.gnome-system-monitor";
      command = "gnome-system-monitor";
      class = "org.gnome.SystemMonitor";
    };
    exec = "gnome-system-monitor";
    categories = [
      "monitor"
      "process"
      "system"
    ];
  };

  plasma-systemmonitor = {
    family = "plasma";
    names = {
      package = "plasma-systemmonitor";
      command = "plasma-systemmonitor";
      class = "org.kde.plasma-systemmonitor";
    };
    exec = "plasma-systemmonitor";
    categories = [
      "monitor"
      "process"
      "system"
    ];
  };
}
