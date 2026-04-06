{...}: {
  #~@ Wayland — Standalone WMs
  hyprland = {
    protocol = ["wayland"];
    role = "standalone";
    language = "c++";
    maturity = "stable";
    categories = ["interface" "compositor"];
  };
  niri = {
    protocol = ["wayland"];
    role = "standalone";
    language = "rust";
    maturity = "stable";
    categories = ["interface" "compositor"];
  };
  sway = {
    protocol = ["wayland"];
    role = "standalone";
    language = "c";
    maturity = "stable";
    categories = ["interface" "compositor"];
  };
  river = {
    protocol = ["wayland"];
    role = "standalone";
    language = "zig";
    maturity = "young";
    categories = ["interface" "compositor"];
  };
  cosmic-comp = {
    protocol = ["wayland"];
    role = "standalone";
    language = "rust";
    maturity = "young";
    categories = ["interface" "compositor"];
  };

  #~@ Wayland — Embedded DE compositors
  mutter = {
    protocol = ["wayland"];
    role = "embedded";
    language = "c";
    maturity = "stable";
    categories = ["interface" "compositor"];
  };
  kwin = {
    protocol = ["wayland"];
    role = "embedded";
    language = "c++";
    maturity = "stable";
    categories = ["interface" "compositor"];
  };

  #~@ Xorg — Standalone WMs
  i3 = {
    protocol = ["xorg"];
    role = "standalone";
    language = "c";
    maturity = "stable";
    categories = ["interface" "compositor"];
  };
  bspwm = {
    protocol = ["xorg"];
    role = "standalone";
    language = "c";
    maturity = "stable";
    categories = ["interface" "compositor"];
  };
  qtile = {
    protocol = ["xorg"];
    role = "standalone";
    language = "python";
    maturity = "stable";
    categories = ["interface" "compositor"];
  };
  awesome = {
    protocol = ["xorg"];
    role = "standalone";
    language = "c";
    maturity = "stable";
    categories = ["interface" "compositor"];
  };
  xmonad = {
    protocol = ["xorg"];
    role = "standalone";
    language = "haskell";
    maturity = "stable";
    categories = ["interface" "compositor"];
  };
  openbox = {
    protocol = ["xorg"];
    role = "standalone";
    language = "c";
    maturity = "legacy";
    categories = ["interface" "compositor"];
  };

  #~@ Xorg — Embedded DE compositors
  xfwm4 = {
    protocol = ["xorg"];
    role = "embedded";
    language = "c";
    maturity = "stable";
    categories = ["interface" "compositor"];
  };
  muffin = {
    protocol = ["xorg"];
    role = "embedded";
    language = "c";
    maturity = "stable";
    categories = ["interface" "compositor"];
  };

  #~@ DE Shells (fused compositor + panel)
  gnome-shell = {
    protocol = ["wayland"];
    role = "shell";
    language = "javascript";
    maturity = "stable";
    categories = ["interface" "compositor"];
  };
  plasmashell = {
    protocol = ["wayland"];
    role = "shell";
    language = "c++";
    maturity = "stable";
    categories = ["interface" "compositor"];
  };
  cosmic-panel = {
    protocol = ["wayland"];
    role = "shell";
    language = "rust";
    maturity = "young";
    categories = ["interface" "compositor"];
  };
  cinnamon = {
    protocol = ["xorg"];
    role = "shell";
    language = "c";
    maturity = "stable";
    categories = ["interface" "compositor"];
  };
  xfce4-panel = {
    protocol = ["xorg"];
    role = "shell";
    language = "c";
    maturity = "stable";
    categories = ["interface" "compositor"];
  };
  gala = {
    protocol = ["xorg"];
    role = "shell";
    language = "vala";
    maturity = "stable";
    categories = ["interface" "compositor"];
  };
}
