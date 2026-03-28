{
  vicinae = {
    names = {
      package = "vicinae";
      command = "vicinae";
    };
    exec = "vicinae";
    categories = ["launcher"];
  };

  rofi = {
    names = {
      package = "rofi";
      command = "rofi";
      class = "rofi";
    };
    exec = "rofi -show drun";
    categories = ["launcher"];
  };

  wofi = {
    names = {
      package = "wofi";
      command = "wofi";
      class = "wofi";
    };
    exec = "wofi --show drun";
    categories = ["launcher"];
  };

  fuzzel = {
    names = {
      package = "fuzzel";
      command = "fuzzel";
      class = "fuzzel";
    };
    exec = "fuzzel";
    categories = ["launcher"];
  };

  anyrun = {
    names = {
      package = "anyrun";
      command = "anyrun";
      class = "anyrun";
    };
    exec = "anyrun";
    categories = ["launcher"];
  };

  walker = {
    names = {
      package = "walker";
      command = "walker";
      class = "walker";
    };
    exec = "walker";
    categories = ["launcher"];
  };

  tofi = {
    names = {
      package = "tofi";
      command = "tofi-drun";
      class = "tofi";
    };
    exec = "tofi-drun";
    categories = ["launcher"];
  };

  albert = {
    names = {
      package = "albert";
      command = "albert";
      class = "albert";
    };
    exec = "albert";
    categories = ["launcher"];
  };

  ulauncher = {
    names = {
      package = "ulauncher";
      command = "ulauncher";
      class = "ulauncher";
    };
    exec = "ulauncher";
    categories = ["launcher"];
  };

  krunner = {
    names = {
      package = "krunner";
      command = "krunner";
      class = "krunner";
    };
    exec = "krunner";
    categories = ["launcher"];
  };

  dmenu = {
    names = {
      package = "dmenu";
      command = "dmenu_run";
    };
    exec = "dmenu_run";
    categories = ["launcher"];
  };

  xfce4-appfinder = {
    names = {
      package = "xfce.xfce4-appfinder";
      command = "xfce4-appfinder";
      class = "xfce4-appfinder";
    };
    exec = "xfce4-appfinder";
    categories = ["launcher"];
  };

  # builtin launchers — no exec, managed by the DE/WM itself
  gnome-shell-overview = {
    names = {
      package = "gnome-shell";
      command = "gnome-shell";
    };
    exec = "";
    builtin = true;
    categories = ["launcher"];
  };

  slingshot = {
    names = {
      package = "pantheon.elementary-applications-menu";
      command = "io.elementary.applications-menu";
    };
    exec = "";
    builtin = true;
    categories = ["launcher"];
  };

  cinnamon-menu = {
    names = {
      package = "cinnamon";
      command = "cinnamon";
    };
    exec = "";
    builtin = true;
    categories = ["launcher"];
  };

  cosmic-launcher = {
    names = {
      package = "cosmic-launcher";
      command = "cosmic-launcher";
    };
    exec = "";
    builtin = true;
    categories = ["launcher"];
  };
}
