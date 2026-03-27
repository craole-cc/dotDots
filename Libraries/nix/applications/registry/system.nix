{
  htop = {
    names = {
      package = "htop";
      command = "htop";
      title = "htop";
    };
    exec = "htop";
    needsTerminal = true;
    categories = ["system"];
  };

  btop = {
    names = {
      package = "btop";
      command = "btop";
      title = "btop";
    };
    exec = "btop";
    needsTerminal = true;
    categories = ["system"];
  };

  nvtop = {
    names = {
      package = "nvtop";
      command = "nvtop";
      title = "nvtop";
    };
    exec = "nvtop";
    needsTerminal = true;
    categories = ["system"];
  };

  mission-center = {
    names = {
      package = "mission-center";
      command = "missioncenter";
      class = "io.missioncenter.MissionCenter";
    };
    exec = "missioncenter";
    categories = ["system"];
  };

  gnome-system-monitor = {
    names = {
      package = "gnome.gnome-system-monitor";
      command = "gnome-system-monitor";
      class = "org.gnome.SystemMonitor";
    };
    exec = "gnome-system-monitor";
    categories = ["system"];
  };

  plasma-systemmonitor = {
    names = {
      package = "plasma-systemmonitor";
      command = "plasma-systemmonitor";
      class = "org.kde.plasma-systemmonitor";
    };
    exec = "plasma-systemmonitor";
    categories = ["system"];
  };
}
