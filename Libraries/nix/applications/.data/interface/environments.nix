{
  #~@ Desktop Environments
  gnome = {
    kind = "desktop";
    protocol = ["wayland" "xorg"];
    greeter = "gdm";
    compositor = {
      shell = "gnome-shell";
      window = "mutter";
    };
    panel = "gnome-shell";
    notifier = "gnome-shell";
  };
  plasma = {
    kind = "desktop";
    protocol = ["wayland" "xorg"];
    greeter = "plasma-login-shell";
    compositor = {
      shell = "plasmashell";
      window = "kwin";
    };
    panel = "plasmashell";
    notifier = "plasmashell";
  };
  cosmic = {
    kind = "desktop";
    protocol = ["wayland"];
    greeter = "cosmic-greeter";
    compositor = {
      shell = "cosmic-panel";
      window = "cosmic-comp";
    };
    panel = "cosmic-panel";
    notifier = "cosmic-notifications";
  };
  pantheon = {
    kind = "desktop";
    protocol = ["xorg"];
    greeter = "lightdm";
    compositor = {
      shell = "gala";
      window = "gala";
    };
    panel = "wingpanel";
    notifier = "notification-daemon";
  };
  cinnamon = {
    kind = "desktop";
    protocol = ["xorg"];
    greeter = "lightdm";
    compositor = {
      shell = "cinnamon";
      window = "muffin";
    };
    panel = "cinnamon";
    notifier = "cinnamon";
  };
  xfce = {
    kind = "desktop";
    protocol = ["xorg"];
    greeter = "lightdm";
    compositor = {
      shell = "xfce4-panel";
      window = "xfwm4";
    };
    panel = "xfce4-panel";
    notifier = "xfce4-notifyd";
  };

  #~@ Standalone WMs — Wayland
  hyprland = {
    kind = "standalone";
    protocol = ["wayland"];
    greeter = "dms-greeter";
    compositor = {
      shell = null;
      window = "hyprland";
    };
    panel = "dms-shell";
    notifier = "dms-shell";
  };
  niri = {
    kind = "standalone";
    protocol = ["wayland"];
    greeter = "dms-greeter";
    compositor = {
      shell = null;
      window = "niri";
    };
    panel = "dms-shell";
    notifier = "dms-shell";
  };
  sway = {
    kind = "standalone";
    protocol = ["wayland"];
    greeter = "dms-greeter";
    compositor = {
      shell = null;
      window = "sway";
    };
    panel = "dms-shell";
    notifier = "dms-shell";
  };
  river = {
    kind = "standalone";
    protocol = ["wayland"];
    greeter = "dms-greeter";
    compositor = {
      shell = null;
      window = "river";
    };
    panel = "dms-shell";
    notifier = "dms-shell";
  };

  #~@ Standalone WMs — Xorg
  i3 = {
    kind = "standalone";
    protocol = ["xorg"];
    greeter = "regreet";
    compositor = {
      shell = null;
      window = "i3";
    };
    panel = "polybar";
    notifier = "dunst";
  };
  bspwm = {
    kind = "standalone";
    protocol = ["xorg"];
    greeter = "regreet";
    compositor = {
      shell = null;
      window = "bspwm";
    };
    panel = "polybar";
    notifier = "dunst";
  };
  qtile = {
    kind = "standalone";
    protocol = ["xorg"];
    greeter = "regreet";
    compositor = {
      shell = null;
      window = "qtile";
    };
    panel = "qtile";
    notifier = "dunst";
  };
  awesome = {
    kind = "standalone";
    protocol = ["xorg"];
    greeter = "regreet";
    compositor = {
      shell = null;
      window = "awesome";
    };
    panel = "awesome";
    notifier = "dunst";
  };
  xmonad = {
    kind = "standalone";
    protocol = ["xorg"];
    greeter = "regreet";
    compositor = {
      shell = null;
      window = "xmonad";
    };
    panel = "xmobar";
    notifier = "dunst";
  };
  openbox = {
    kind = "standalone";
    protocol = ["xorg"];
    greeter = "regreet";
    compositor = {
      shell = null;
      window = "openbox";
    };
    panel = "tint2";
    notifier = "xfce4-notifyd";
  };
}
