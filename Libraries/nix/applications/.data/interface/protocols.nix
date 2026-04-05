{
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
}
