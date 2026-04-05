{
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
}
