{...}: let
  __exports = {
    internal = registry;
    external.interfaceRegistry = registry;
  };

  registry = {
    compositors = {
      #~@ Wayland — Standalone WMs
      hyprland = {
        protocol = ["wayland"];
        role = "standalone";
        language = "c++";
        maturity = "stable";
      };
      niri = {
        protocol = ["wayland"];
        role = "standalone";
        language = "rust";
        maturity = "stable";
      };
      sway = {
        protocol = ["wayland"];
        role = "standalone";
        language = "c";
        maturity = "stable";
      };
      river = {
        protocol = ["wayland"];
        role = "standalone";
        language = "zig";
        maturity = "young";
      };
      cosmic-comp = {
        protocol = ["wayland"];
        role = "standalone";
        language = "rust";
        maturity = "young";
      };

      #~@ Wayland — Embedded DE compositors
      mutter = {
        protocol = ["wayland"];
        role = "embedded";
        language = "c";
        maturity = "stable";
      };
      kwin = {
        protocol = ["wayland"];
        role = "embedded";
        language = "c++";
        maturity = "stable";
      };

      #~@ Xorg — Standalone WMs
      i3 = {
        protocol = ["xorg"];
        role = "standalone";
        language = "c";
        maturity = "stable";
      };
      bspwm = {
        protocol = ["xorg"];
        role = "standalone";
        language = "c";
        maturity = "stable";
      };
      qtile = {
        protocol = ["xorg"];
        role = "standalone";
        language = "python";
        maturity = "stable";
      };
      awesome = {
        protocol = ["xorg"];
        role = "standalone";
        language = "c";
        maturity = "stable";
      };
      xmonad = {
        protocol = ["xorg"];
        role = "standalone";
        language = "haskell";
        maturity = "stable";
      };
      openbox = {
        protocol = ["xorg"];
        role = "standalone";
        language = "c";
        maturity = "legacy";
      };

      #~@ Xorg — Embedded DE compositors
      xfwm4 = {
        protocol = ["xorg"];
        role = "embedded";
        language = "c";
        maturity = "stable";
      };
      muffin = {
        protocol = ["xorg"];
        role = "embedded";
        language = "c";
        maturity = "stable";
      };

      #~@ DE Shells (fused compositor + panel)
      gnome-shell = {
        protocol = ["wayland"];
        role = "shell";
        language = "javascript";
        maturity = "stable";
      };
      plasmashell = {
        protocol = ["wayland"];
        role = "shell";
        language = "c++";
        maturity = "stable";
      };
      cosmic-panel = {
        protocol = ["wayland"];
        role = "shell";
        language = "rust";
        maturity = "young";
      };
      cinnamon = {
        protocol = ["xorg"];
        role = "shell";
        language = "c";
        maturity = "stable";
      };
      xfce4-panel = {
        protocol = ["xorg"];
        role = "shell";
        language = "c";
        maturity = "stable";
      };
      gala = {
        protocol = ["xorg"];
        role = "shell";
        language = "vala";
        maturity = "stable";
      };
    };
    environments = {
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
    };
    greeters = {
      cosmic-greeter = {
        protocol = ["wayland"];
        display = "graphical";
        language = "rust";
        maturity = "young";
      };
      dms-greeter = {
        protocol = ["wayland"];
        display = "graphical";
        language = "rust";
        maturity = "young";
      };
      gdm = {
        protocol = ["wayland" "xorg"];
        display = "graphical";
        language = "c";
        maturity = "stable";
      };
      greetd = {
        protocol = ["wayland" "xorg" "tty" "kms"];
        display = "terminal";
        language = "rust";
        maturity = "stable";
      };
      lemurs = {
        protocol = ["wayland" "xorg" "tty" "kms"];
        display = "terminal";
        language = "rust";
        maturity = "young";
      };
      lightdm = {
        protocol = ["wayland" "xorg"];
        display = "graphical";
        language = "c";
        maturity = "legacy";
      };
      ly = {
        protocol = ["wayland" "xorg" "tty" "kms"];
        display = "terminal";
        language = "zig";
        maturity = "niche";
      };
      plasma-login-shell = {
        protocol = ["wayland" "xorg"];
        display = "graphical";
        language = "c++";
        maturity = "stable";
      };
      regreet = {
        protocol = ["wayland" "xorg"];
        display = "graphical";
        language = "rust";
        maturity = "stable";
      };
      sddm = {
        protocol = ["wayland" "xorg"];
        display = "graphical";
        language = "c++";
        maturity = "stable";
      };
      tuigreet = {
        protocol = ["wayland" "tty" "kms"];
        display = "terminal";
        language = "rust";
        maturity = "stable";
      };
    };
    notifiers = {
      #~@ DE-integrated
      gnome-shell = {
        protocol = ["wayland"];
        integrated = true;
        language = "javascript";
        maturity = "stable";
      };
      plasmashell = {
        protocol = ["wayland"];
        integrated = true;
        language = "c++";
        maturity = "stable";
      };
      cosmic-notifications = {
        protocol = ["wayland"];
        integrated = true;
        language = "rust";
        maturity = "young";
      };
      cinnamon = {
        protocol = ["xorg"];
        integrated = true;
        language = "c";
        maturity = "stable";
      };
      xfce4-notifyd = {
        protocol = ["xorg"];
        integrated = true;
        language = "c";
        maturity = "stable";
      };
      notification-daemon = {
        protocol = ["xorg"];
        integrated = true;
        language = "c";
        maturity = "legacy";
      };

      #~@ Standalone Wayland
      mako = {
        protocol = ["wayland"];
        integrated = false;
        language = "c";
        maturity = "stable";
      };
      fnott = {
        protocol = ["wayland"];
        integrated = false;
        language = "c";
        maturity = "stable";
      };
      dms-shell = {
        protocol = ["wayland"];
        integrated = false;
        language = "rust";
        maturity = "young";
      };

      #~@ Standalone — any protocol
      dunst = {
        protocol = ["wayland" "xorg"];
        integrated = false;
        language = "c";
        maturity = "stable";
      };
      deadd-notification-center = {
        protocol = ["xorg"];
        integrated = false;
        language = "haskell";
        maturity = "niche";
      };
    };
    panels = {
      #~@ DE-integrated
      gnome-shell = {
        protocol = ["wayland"];
        integrated = true;
        language = "javascript";
        maturity = "stable";
      };
      plasmashell = {
        protocol = ["wayland"];
        integrated = true;
        language = "c++";
        maturity = "stable";
      };
      cosmic-panel = {
        protocol = ["wayland"];
        integrated = true;
        language = "rust";
        maturity = "young";
      };
      cinnamon = {
        protocol = ["xorg"];
        integrated = true;
        language = "c";
        maturity = "stable";
      };
      xfce4-panel = {
        protocol = ["xorg"];
        integrated = true;
        language = "c";
        maturity = "stable";
      };
      wingpanel = {
        protocol = ["xorg"];
        integrated = true;
        language = "vala";
        maturity = "stable";
      };

      #~@ WM-native (built into the WM, not a DE)
      awesome = {
        protocol = ["xorg"];
        integrated = false;
        language = "c";
        maturity = "stable";
      };
      qtile = {
        protocol = ["xorg"];
        integrated = false;
        language = "python";
        maturity = "stable";
      };
      xmobar = {
        protocol = ["xorg"];
        integrated = false;
        language = "haskell";
        maturity = "stable";
      };

      #~@ Standalone Wayland
      waybar = {
        protocol = ["wayland"];
        integrated = false;
        language = "c++";
        maturity = "stable";
      };
      dms-shell = {
        protocol = ["wayland"];
        integrated = false;
        language = "rust";
        maturity = "young";
      };

      #~@ Standalone Xorg
      polybar = {
        protocol = ["xorg"];
        integrated = false;
        language = "c++";
        maturity = "stable";
      };
      tint2 = {
        protocol = ["xorg"];
        integrated = false;
        language = "c";
        maturity = "legacy";
      };
    };
    protocols = {
      tty = {
        surface = "console";
        acceleration = false;
        compositing = false;
        remote = false;
        maturity = "stable";
      };
      kms = {
        surface = "framebuffer";
        acceleration = true;
        compositing = false;
        remote = false;
        maturity = "stable";
      };
      wayland = {
        surface = "native";
        acceleration = true;
        compositing = true;
        remote = true;
        maturity = "stable";
      };
      xorg = {
        surface = "native";
        acceleration = true;
        compositing = true;
        remote = true;
        maturity = "legacy";
      };
    };
  };
in
  __exports.internal // {_rootAliases = __exports.external;}
