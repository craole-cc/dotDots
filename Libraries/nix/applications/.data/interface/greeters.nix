{
  cosmic-greeter = {
    protocol = ["wayland"];
    display = "graphical";
    language = "rust";
    maturity = "young";
  };
  dms-greeter = {
    protocol = ["wayland"];
    display = "graphical";
    language = "rust";
    maturity = "young";
  };
  gdm = {
    protocol = ["wayland" "xorg"];
    display = "graphical";
    language = "c";
    maturity = "stable";
  };
  greetd = {
    protocol = ["wayland" "xorg" "tty" "kms"];
    display = "terminal";
    language = "rust";
    maturity = "stable";
  };
  lemurs = {
    protocol = ["wayland" "xorg" "tty" "kms"];
    display = "terminal";
    language = "rust";
    maturity = "young";
  };
  lightdm = {
    protocol = ["wayland" "xorg"];
    display = "graphical";
    language = "c";
    maturity = "legacy";
  };
  ly = {
    protocol = ["wayland" "xorg" "tty" "kms"];
    display = "terminal";
    language = "zig";
    maturity = "niche";
  };
  plasma-login-shell = {
    protocol = ["wayland" "xorg"];
    display = "graphical";
    language = "c++";
    maturity = "stable";
  };
  regreet = {
    protocol = ["wayland" "xorg"];
    display = "graphical";
    language = "rust";
    maturity = "stable";
  };
  sddm = {
    protocol = ["wayland" "xorg"];
    display = "graphical";
    language = "c++";
    maturity = "stable";
  };
  tuigreet = {
    protocol = ["wayland" "tty" "kms"];
    display = "terminal";
    language = "rust";
    maturity = "stable";
  };
}
