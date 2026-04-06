{...}: {
  cosmic-greeter = {
    categories = ["interface" "greeter"];
    protocol = ["wayland"];
    display = "graphical";
    language = "rust";
    maturity = "young";
  };
  dms-greeter = {
    categories = ["interface" "greeter"];
    protocol = ["wayland"];
    display = "graphical";
    language = "rust";
    maturity = "young";
  };
  gdm = {
    categories = ["interface" "greeter"];
    protocol = ["wayland" "xorg"];
    display = "graphical";
    language = "c";
    maturity = "stable";
  };
  greetd = {
    categories = ["interface" "greeter"];
    protocol = ["wayland" "xorg" "tty" "kms"];
    display = "terminal";
    language = "rust";
    maturity = "stable";
  };
  lemurs = {
    categories = ["interface" "greeter"];
    protocol = ["wayland" "xorg" "tty" "kms"];
    display = "terminal";
    language = "rust";
    maturity = "young";
  };
  lightdm = {
    categories = ["interface" "greeter"];
    protocol = ["wayland" "xorg"];
    display = "graphical";
    language = "c";
    maturity = "legacy";
  };
  ly = {
    categories = ["interface" "greeter"];
    protocol = ["wayland" "xorg" "tty" "kms"];
    display = "terminal";
    language = "zig";
    maturity = "niche";
  };
  plasma-login-shell = {
    categories = ["interface" "greeter"];
    protocol = ["wayland" "xorg"];
    display = "graphical";
    language = "c++";
    maturity = "stable";
  };
  regreet = {
    categories = ["interface" "greeter"];
    protocol = ["wayland" "xorg"];
    display = "graphical";
    language = "rust";
    maturity = "stable";
  };
  sddm = {
    categories = ["interface" "greeter"];
    protocol = ["wayland" "xorg"];
    display = "graphical";
    language = "c++";
    maturity = "stable";
  };
  tuigreet = {
    categories = ["interface" "greeter"];
    protocol = ["wayland" "tty" "kms"];
    display = "terminal";
    language = "rust";
    maturity = "stable";
  };
}
