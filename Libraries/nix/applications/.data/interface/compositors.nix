{
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
}
