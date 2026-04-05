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
}
