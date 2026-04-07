{...}: {
  awesome = {
    categories = ["panel" "interface"];
    independent = true;
    engine = ["c" "lua"];
    config = ["lua"];
    maturity = "stable";
    protocol = ["xorg"];
    toolkit = "cairo";
  };

  caelestia = {
    categories = ["panel" "interface"];
    independent = true;
    engine = ["c++" "qml"];
    config = ["qml"];
    maturity = "young";
    protocol = ["wayland"];
    toolkit = "qt6";
  };

  cinnamon = {
    categories = ["panel" "interface"];
    independent = false;
    engine = ["c"];
    config = ["javascript" "css"];
    maturity = "stable";
    protocol = ["xorg"];
    toolkit = "gtk3";
  };

  cosmic-panel = {
    categories = ["panel" "interface"];
    independent = false;
    engine = ["rust"];
    config = ["ron" "css"];
    maturity = "young";
    protocol = ["wayland"];
    toolkit = "iced";
  };

  dms-shell = {
    categories = ["panel" "interface"];
    independent = true;
    engine = ["go"];
    config = ["qml"];
    maturity = "young";
    protocol = ["wayland"];
    toolkit = "qt6";
  };

  eww = {
    categories = ["panel" "interface"];
    independent = true;
    engine = ["rust"];
    config = ["yuck" "scss"];
    maturity = "stable";
    protocol = ["wayland" "xorg"];
    toolkit = "gtk3";
  };

  exo = {
    categories = ["panel" "interface"];
    independent = true;
    engine = ["python"];
    config = ["python" "scss"];
    maturity = "young";
    protocol = ["wayland"];
    toolkit = "gtk4";
  };

  gnome-shell = {
    categories = ["panel" "interface"];
    independent = false;
    engine = ["c" "javascript"];
    config = ["javascript" "css"];
    maturity = "stable";
    protocol = ["wayland" "xorg"];
    toolkit = "st";
  };

  i3bar = {
    categories = ["panel" "interface"];
    independent = false;
    engine = ["c"];
    config = ["json" "shell"];
    maturity = "stable";
    protocol = ["xorg"];
    toolkit = "xcb";
  };

  hyprpanel = {
    categories = ["panel" "interface"];
    independent = true;
    engine = ["typescript"];
    config = ["typescript" "scss"];
    maturity = "young";
    protocol = ["wayland"];
    toolkit = "gtk3";
  };

  lemonbar = {
    categories = ["panel" "interface"];
    independent = true;
    engine = ["c"];
    config = ["shell"];
    maturity = "stable";
    protocol = ["xorg"];
    toolkit = "xcb";
  };

  noctalia = {
    categories = ["panel" "interface"];
    independent = true;
    engine = ["c++"];
    config = ["qml"];
    maturity = "young";
    protocol = ["wayland"];
    toolkit = "qt6";
  };

  nwg-panel = {
    categories = ["panel" "interface"];
    independent = true;
    engine = ["python"];
    config = ["json" "css"];
    maturity = "stable";
    protocol = ["wayland"];
    toolkit = "gtk3";
  };

  plasmashell = {
    categories = ["panel" "interface"];
    independent = false;
    engine = ["c++" "qml"];
    config = ["qml" "javascript"];
    maturity = "stable";
    protocol = ["wayland" "xorg"];
    toolkit = "qt6";
  };

  polybar = {
    categories = ["panel" "interface"];
    independent = true;
    engine = ["c++"];
    config = ["ini" "shell"];
    maturity = "stable";
    protocol = ["xorg"];
    toolkit = "cairo";
  };

  qtile = {
    categories = ["panel" "interface"];
    independent = false;
    engine = ["python" "c"];
    config = ["python"];
    maturity = "stable";
    protocol = ["xorg" "wayland"];
    toolkit = "cairo";
  };

  swaybar = {
    categories = ["panel" "interface"];
    independent = false;
    engine = ["c"];
    config = ["shell" "json"];
    maturity = "stable";
    protocol = ["wayland"];
    toolkit = "cairo";
  };

  tint2 = {
    categories = ["panel" "interface"];
    independent = true;
    engine = ["c"];
    config = ["ini"];
    maturity = "legacy";
    protocol = ["xorg"];
    toolkit = "pango";
  };

  waybar = {
    categories = ["panel" "interface"];
    independent = true;
    engine = ["c++"];
    config = ["jsonc" "css"];
    maturity = "stable";
    protocol = ["wayland"];
    toolkit = "gtk3";
  };

  wingpanel = {
    categories = ["panel" "interface"];
    independent = false;
    engine = ["vala" "c"];
    config = ["css"];
    maturity = "stable";
    protocol = ["xorg" "wayland"];
    toolkit = "gtk3";
  };

  xfce4-panel = {
    categories = ["panel" "interface"];
    independent = false;
    engine = ["c"];
    config = ["rc" "css"];
    maturity = "stable";
    protocol = ["xorg"];
    toolkit = "gtk3";
  };

  xmobar = {
    categories = ["panel" "interface"];
    independent = true;
    engine = ["haskell"];
    config = ["haskell"];
    maturity = "stable";
    protocol = ["xorg"];
    toolkit = "xft";
  };
}
