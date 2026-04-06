{...}: {
  #~@ DE-integrated
  gnome-shell = {
    categories = ["interface" "notifier"];
    protocol = ["wayland"];
    integrated = true;
    language = "javascript";
    maturity = "stable";
  };
  plasmashell = {
    categories = ["interface" "notifier"];
    protocol = ["wayland"];
    integrated = true;
    language = "c++";
    maturity = "stable";
  };
  cosmic-notifications = {
    categories = ["interface" "notifier"];
    protocol = ["wayland"];
    integrated = true;
    language = "rust";
    maturity = "young";
  };
  cinnamon = {
    categories = ["interface" "notifier"];
    protocol = ["xorg"];
    integrated = true;
    language = "c";
    maturity = "stable";
  };
  xfce4-notifyd = {
    categories = ["interface" "notifier"];
    protocol = ["xorg"];
    integrated = true;
    language = "c";
    maturity = "stable";
  };
  notification-daemon = {
    categories = ["interface" "notifier"];
    protocol = ["xorg"];
    integrated = true;
    language = "c";
    maturity = "legacy";
  };

  #~@ Standalone Wayland
  mako = {
    categories = ["interface" "notifier"];
    protocol = ["wayland"];
    integrated = false;
    language = "c";
    maturity = "stable";
  };
  fnott = {
    categories = ["interface" "notifier"];
    protocol = ["wayland"];
    integrated = false;
    language = "c";
    maturity = "stable";
  };
  dms-shell = {
    categories = ["interface" "notifier"];
    protocol = ["wayland"];
    integrated = false;
    language = "rust";
    maturity = "young";
  };

  #~@ Standalone — any protocol
  dunst = {
    categories = ["interface" "notifier"];
    protocol = ["wayland" "xorg"];
    integrated = false;
    language = "c";
    maturity = "stable";
  };
  deadd-notification-center = {
    categories = ["interface" "notifier"];
    protocol = ["xorg"];
    integrated = false;
    language = "haskell";
    maturity = "niche";
  };
}
