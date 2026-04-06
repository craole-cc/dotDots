{...}: {
  #~@ DE-integrated
  gnome-shell = {
    categories = ["interface" "panel"];
    protocol = ["wayland"];
    integrated = true;
    language = "javascript";
    maturity = "stable";
  };
  plasmashell = {
    categories = ["interface" "panel"];
    protocol = ["wayland"];
    integrated = true;
    language = "c++";
    maturity = "stable";
  };
  cosmic-panel = {
    categories = ["interface" "panel"];
    protocol = ["wayland"];
    integrated = true;
    language = "rust";
    maturity = "young";
  };
  cinnamon = {
    categories = ["interface" "panel"];
    protocol = ["xorg"];
    integrated = true;
    language = "c";
    maturity = "stable";
  };
  xfce4-panel = {
    categories = ["interface" "panel"];
    protocol = ["xorg"];
    integrated = true;
    language = "c";
    maturity = "stable";
  };
  wingpanel = {
    categories = ["interface" "panel"];
    protocol = ["xorg"];
    integrated = true;
    language = "vala";
    maturity = "stable";
  };

  #~@ WM-native (built into the WM, not a DE)
  awesome = {
    categories = ["interface" "panel"];
    protocol = ["xorg"];
    integrated = false;
    language = "c";
    maturity = "stable";
  };
  qtile = {
    categories = ["interface" "panel"];
    protocol = ["xorg"];
    integrated = false;
    language = "python";
    maturity = "stable";
  };
  xmobar = {
    categories = ["interface" "panel"];
    protocol = ["xorg"];
    integrated = false;
    language = "haskell";
    maturity = "stable";
  };

  #~@ Standalone Wayland
  waybar = {
    categories = ["interface" "panel"];
    protocol = ["wayland"];
    integrated = false;
    language = "c++";
    maturity = "stable";
  };
  dms-shell = {
    categories = ["interface" "panel"];
    protocol = ["wayland"];
    integrated = false;
    language = "rust";
    maturity = "young";
  };

  #~@ Standalone Xorg
  polybar = {
    categories = ["interface" "panel"];
    protocol = ["xorg"];
    integrated = false;
    language = "c++";
    maturity = "stable";
  };
  tint2 = {
    categories = ["interface" "panel"];
    protocol = ["xorg"];
    integrated = false;
    language = "c";
    maturity = "legacy";
  };
}
