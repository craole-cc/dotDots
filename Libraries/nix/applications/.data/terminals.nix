{...}: {
  foot = {
    names = {
      package = "foot";
      command = "foot";
      class = "foot";
    };
    exec = "foot";
    wrap = {
      titleFlag = "--title";
      execFlag = "-e";
    };
    protocol = ["wayland"];
    categories = ["terminal"];
  };

  ghostty = {
    names = {
      package = "ghostty";
      command = "ghostty";
      class = "com.mitchellh.ghostty";
    };
    exec = "ghostty";
    wrap = {
      titleFlag = "--title";
      execFlag = "-e";
    };
    categories = ["terminal"];
  };

  kitty = {
    names = {
      package = "kitty";
      command = "kitty";
      class = "kitty";
    };
    exec = "kitty";
    wrap = {
      titleFlag = "--title";
      execFlag = "--";
    };
    categories = ["terminal"];
  };

  alacritty = {
    names = {
      package = "alacritty";
      command = "alacritty";
      class = "Alacritty";
    };
    exec = "alacritty";
    wrap = {
      titleFlag = "--title";
      execFlag = "-e";
    };
    categories = ["terminal"];
  };

  wezterm = {
    names = {
      package = "wezterm";
      command = "wezterm";
      class = "org.wezfurlong.wezterm";
    };
    exec = "wezterm";
    wrap = {
      titleFlag = "--title";
      execFlag = "start --";
    };
    categories = ["terminal"];
  };

  konsole = {
    names = {
      package = "konsole";
      command = "konsole";
      class = "org.kde.konsole";
    };
    exec = "konsole";
    wrap = {
      titleFlag = "--";
      execFlag = "-e";
    };
    categories = ["terminal"];
  };

  gnome-terminal = {
    names = {
      package = "gnome-terminal";
      command = "gnome-terminal";
      class = "org.gnome.Terminal";
    };
    exec = "gnome-terminal";
    wrap = {
      titleFlag = "--title";
      execFlag = "--";
    };
    categories = ["terminal"];
  };

  xfce4-terminal = {
    names = {
      package = "xfce4-terminal";
      command = "xfce4-terminal";
      class = "xfce4-terminal";
    };
    exec = "xfce4-terminal";
    wrap = {
      titleFlag = "--title";
      execFlag = "-e";
    };
    categories = ["terminal"];
  };

  cosmic-terminal = {
    names = {
      package = "cosmic-term";
      command = "cosmic-term";
      class = "com.system76.CosmicTerm";
    };
    exec = "cosmic-term";
    wrap = {
      titleFlag = "--title";
      execFlag = "-e";
    };
    categories = ["terminal"];
  };

  pantheon-terminal = {
    names = {
      package = "pantheon.elementary-terminal";
      command = "io.elementary.terminal";
      class = "io.elementary.terminal";
    };
    exec = "io.elementary.terminal";
    wrap = {
      titleFlag = "--title";
      execFlag = "-x";
    };
    categories = ["terminal"];
  };

  xterm = {
    names = {
      package = "xterm";
      command = "xterm";
      class = "XTerm";
    };
    exec = "xterm";
    wrap = {
      titleFlag = "-T";
      execFlag = "-e";
    };
    protocol = ["xorg"];
    categories = ["terminal"];
  };

  st = {
    names = {
      package = "st";
      command = "st";
      class = "st";
    };
    exec = "st";
    wrap = {
      titleFlag = "-t";
      execFlag = "-e";
    };
    protocol = ["xorg"];
    categories = ["terminal"];
  };

  urxvt = {
    names = {
      package = "rxvt-unicode";
      command = "urxvt";
      class = "URxvt";
    };
    exec = "urxvt";
    wrap = {
      titleFlag = "-title";
      execFlag = "-e";
    };
    protocol = ["xorg"];
    categories = ["terminal"];
  };

  tilix = {
    names = {
      package = "tilix";
      command = "tilix";
      class = "com.gexperts.Tilix";
    };
    exec = "tilix";
    wrap = {
      titleFlag = "--title";
      execFlag = "-e";
    };
    categories = ["terminal"];
  };
}
