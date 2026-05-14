_: {
  #~@ Desktop Environments
  cinnamon = {
    categories = [
      "environment"
      "interface"
    ];
    compositor = "muffin";
    greeters = [ "lightdm" ];
    layouts = [
      "floating"
      "stacking"
    ];
    notifier = [ "cinnamon" ];
    panel = [ "cinnamon" ];
    protocol = [ "xorg" ];
    scope = "desktop";
  };

  cosmic = {
    categories = [
      "environment"
      "interface"
    ];
    compositor = "cosmic-comp";
    greeters = [
      "cosmic-greeter"
      "greetd"
    ];
    layouts = [
      "floating"
      "stacking"
      "tiling"
    ];
    notifier = [ "cosmic-notifications" ];
    panel = [ "cosmic-panel" ];
    protocol = [ "wayland" ];
    scope = "desktop";
  };

  gnome = {
    categories = [
      "environment"
      "interface"
    ];
    compositor = "mutter";
    greeters = [ "gdm" ];
    layouts = [
      "floating"
      "stacking"
      "tiling"
    ];
    notifier = [ "gnome-shell" ];
    panel = [ "gnome-shell" ];
    protocol = [
      "wayland"
      "xorg"
    ];
    scope = "desktop";
  };

  pantheon = {
    categories = [
      "environment"
      "interface"
    ];
    compositor = "gala";
    greeters = [ "lightdm" ];
    layouts = [
      "floating"
      "stacking"
      "tiling"
    ];
    notifier = [ "notification-daemon" ];
    panel = [ "wingpanel" ];
    protocol = [ "xorg" ];
    scope = "desktop";
  };

  plasma = {
    categories = [
      "environment"
      "interface"
    ];
    compositor = "kwin";
    greeters = [
      "sddm"
      "plasma-login-shell"
    ];
    layouts = [
      "floating"
      "stacking"
      "tiling"
    ];
    notifier = [ "plasmashell" ];
    panel = [ "plasmashell" ];
    protocol = [
      "wayland"
      "xorg"
    ];
    scope = "desktop";
  };

  xfce = {
    categories = [
      "environment"
      "interface"
    ];
    compositor = "xfwm4";
    greeters = [ "lightdm" ];
    layouts = [
      "floating"
      "stacking"
    ];
    notifier = [ "xfce4-notifyd" ];
    panel = [ "xfce4-panel" ];
    protocol = [ "xorg" ];
    scope = "desktop";
  };

  #~@ Standalone WMs — Wayland
  hyprland = {
    categories = [
      "environment"
      "interface"
    ];
    compositor = "hyprland";
    greeters = [
      "regreet"
      "dms-greeter"
      "greetd"
      "tuigreet"
      "ly"
    ];
    layouts = [
      "tiling"
      "floating"
      "stacking"
    ];
    notifier = [
      "mako"
      "dms-shell"
      "swaync"
    ];
    panel = [
      "hyprpanel"
      "dms-shell"
      "caelestia"
      "exo"
      "noctalia"
      "waybar"
      "nwg-panel"
      "eww"
    ];
    protocol = [ "wayland" ];
    scope = "compositor";
  };

  niri = {
    categories = [
      "environment"
      "interface"
    ];
    compositor = "niri";
    greeters = [
      "regreet"
      "dms-greeter"
      "greetd"
      "tuigreet"
      "ly"
    ];
    layouts = [
      "tiling"
      "floating"
    ];
    notifier = [
      "mako"
      "dms-shell"
      "swaync"
    ];
    panel = [
      "dms-shell"
      "exo"
      "noctalia"
      "waybar"
      "eww"
    ];
    protocol = [ "wayland" ];
    scope = "compositor";
  };

  river = {
    categories = [
      "environment"
      "interface"
    ];
    compositor = "river";
    greeters = [
      "regreet"
      "dms-greeter"
      "greetd"
      "tuigreet"
      "ly"
    ];
    layouts = [
      "tiling"
      "floating"
    ];
    notifier = [
      "mako"
      "dms-shell"
      "swaync"
    ];
    panel = [
      "dms-shell"
      "waybar"
      "eww"
    ];
    protocol = [ "wayland" ];
    scope = "compositor";
  };

  sway = {
    categories = [
      "environment"
      "interface"
    ];
    compositor = "sway";
    greeters = [
      "regreet"
      "dms-greeter"
      "greetd"
      "tuigreet"
      "ly"
    ];
    layouts = [
      "tiling"
      "floating"
      "stacking"
    ];
    notifier = [
      "mako"
      "dms-shell"
      "swaync"
    ];
    panel = [
      "dms-shell"
      "waybar"
      "swaybar"
      "eww"
    ];
    protocol = [ "wayland" ];
    scope = "compositor";
  };

  #~@ Standalone WMs — Xorg
  awesome = {
    categories = [
      "environment"
      "interface"
    ];
    compositor = "awesome";
    greeters = [
      "lightdm"
      "greetd"
      "regreet"
    ];
    layouts = [
      "tiling"
      "floating"
      "stacking"
    ];
    notifier = [ "dunst" ];
    panel = [
      "awesome"
      "polybar"
      "xmobar"
    ];
    protocol = [ "xorg" ];
    scope = "compositor";
  };

  bspwm = {
    categories = [
      "environment"
      "interface"
    ];
    compositor = "bspwm";
    greeters = [
      "lightdm"
      "greetd"
      "regreet"
    ];
    layouts = [
      "tiling"
      "floating"
      "stacking"
    ];
    notifier = [ "dunst" ];
    panel = [
      "polybar"
      "lemonbar"
      "xmobar"
    ];
    protocol = [ "xorg" ];
    scope = "compositor";
  };

  i3 = {
    categories = [
      "environment"
      "interface"
    ];
    compositor = "i3";
    greeters = [
      "lightdm"
      "greetd"
      "regreet"
    ];
    layouts = [
      "tiling"
      "floating"
      "stacking"
    ];
    notifier = [ "dunst" ];
    panel = [
      "i3bar"
      "polybar"
      "lemonbar"
      "xmobar"
    ];
    protocol = [ "xorg" ];
    scope = "compositor";
  };

  openbox = {
    categories = [
      "environment"
      "interface"
    ];
    compositor = "openbox";
    greeters = [
      "lightdm"
      "greetd"
      "regreet"
    ];
    layouts = [
      "floating"
      "stacking"
    ];
    notifier = [
      "dunst"
      "xfce4-notifyd"
    ];
    panel = [
      "tint2"
      "polybar"
      "lemonbar"
    ];
    protocol = [ "xorg" ];
    scope = "compositor";
  };

  qtile = {
    categories = [
      "environment"
      "interface"
    ];
    compositor = "qtile";
    greeters = [
      "lightdm"
      "greetd"
      "regreet"
    ];
    layouts = [
      "tiling"
      "floating"
      "stacking"
    ];
    notifier = [ "dunst" ];
    panel = [
      "qtile"
      "polybar"
      "xmobar"
    ];
    protocol = [ "xorg" ];
    scope = "compositor";
  };

  xmonad = {
    categories = [
      "environment"
      "interface"
    ];
    compositor = "xmonad";
    greeters = [
      "lightdm"
      "greetd"
      "regreet"
    ];
    layouts = [
      "tiling"
      "floating"
      "stacking"
    ];
    notifier = [ "dunst" ];
    panel = [
      "xmobar"
      "polybar"
      "lemonbar"
    ];
    protocol = [ "xorg" ];
    scope = "compositor";
  };
}
