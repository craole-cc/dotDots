{...}: {
  #~@ Daemon

  greetd = {
    categories = ["greeter" "interface"];
    display = "daemon"; # session manager; regreet/tuigreet/dms-greeter etc. run under it
    language = "rust";
    maturity = "stable";
    protocol = ["wayland" "xorg" "tty" "kms"];
  };

  #~@ Graphical

  cosmic-greeter = {
    categories = ["greeter" "interface"];
    display = "graphical";
    language = "rust";
    maturity = "young";
    protocol = ["wayland"];
  };

  dms-greeter = {
    categories = ["greeter" "interface"];
    display = "graphical";
    language = "rust";
    maturity = "young";
    protocol = ["wayland"];
  };

  gdm = {
    categories = ["greeter" "interface"];
    display = "graphical";
    language = "c";
    maturity = "stable";
    protocol = ["wayland" "xorg"];
  };

  lightdm = {
    categories = ["greeter" "interface"];
    display = "graphical";
    language = "c";
    maturity = "legacy";
    protocol = ["wayland" "xorg"];
  };

  plasma-login-shell = {
    categories = ["greeter" "interface"];
    display = "graphical";
    language = "c++";
    maturity = "stable";
    protocol = ["wayland" "xorg"];
  };

  regreet = {
    categories = ["greeter" "interface"];
    display = "graphical";
    language = "rust";
    maturity = "stable";
    protocol = ["wayland" "xorg"];
  };

  sddm = {
    categories = ["greeter" "interface"];
    display = "graphical";
    language = "c++";
    maturity = "stable";
    protocol = ["wayland" "xorg"];
  };

  #~@ Terminal

  lemurs = {
    categories = ["greeter" "interface"];
    display = "terminal";
    language = "rust";
    maturity = "young";
    protocol = ["wayland" "xorg" "tty" "kms"];
  };

  ly = {
    categories = ["greeter" "interface"];
    display = "terminal";
    language = "zig";
    maturity = "young";
    protocol = ["wayland" "xorg" "tty" "kms"];
  };

  tuigreet = {
    categories = ["greeter" "interface"];
    display = "terminal";
    language = "rust";
    maturity = "stable";
    protocol = ["wayland" "xorg" "tty" "kms"];
  };
}
