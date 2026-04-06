{...}: {
  #~@ Desktop Environments
  gnome = {
    categories = ["interface" "environment"];
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
    categories = ["interface" "environment"];
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
    categories = ["interface" "environment"];
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
    categories = ["interface" "environment"];
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
    categories = ["interface" "environment"];
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
    categories = ["interface" "environment"];
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
    categories = ["interface" "environment"];
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
    categories = ["interface" "environment"];
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
    categories = ["interface" "environment"];
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
    categories = ["interface" "environment"];
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
    categories = ["interface" "environment"];
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
    categories = ["interface" "environment"];
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
    categories = ["interface" "environment"];
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
    categories = ["interface" "environment"];
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
    categories = ["interface" "environment"];
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
    categories = ["interface" "environment"];
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
