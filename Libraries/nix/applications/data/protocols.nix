_: {
  tty = {
    categories = [
      "interface"
      "protocol"
    ];
    surface = "console";
    acceleration = false;
    compositing = false;
    remote = false;
    maturity = "legacy";
  };
  kms = {
    categories = [
      "interface"
      "protocol"
    ];
    surface = "native";
    acceleration = true;
    compositing = false;
    remote = false;
    maturity = "stable";
  };
  wayland = {
    categories = [
      "interface"
      "protocol"
    ];
    surface = "native";
    acceleration = true;
    compositing = true;
    remote = true;
    maturity = "stable";
  };
  xorg = {
    categories = [
      "interface"
      "protocol"
    ];
    surface = "native";
    acceleration = true;
    compositing = true;
    remote = true;
    maturity = "legacy";
  };
}
