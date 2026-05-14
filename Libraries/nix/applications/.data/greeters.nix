_: {
  cosmic-greeter = {
    categories = [
      "greeter"
      "interface"
    ];
    kind = "graphical";
    family = "cosmic";
    independent = false;
    engine = [ "rust" ];
    config = [
      "ron"
      "css"
    ];
    maturity = "young";
    protocol = [ "wayland" ];
    toolkit = "iced";
  };
  dms-greeter = {
    categories = [
      "greeter"
      "interface"
    ];
    family = "dms";
    kind = "graphical";
    independent = true;
    engine = [ "rust" ];
    config = [ "toml" ];
    maturity = "young";
    protocol = [ "wayland" ];
    toolkit = "gtk4";
  };
  gdm = {
    categories = [
      "greeter"
      "interface"
    ];
    kind = "graphical";
    family = "gnome";
    independent = false;
    engine = [ "c" ];
    config = [
      "javascript"
      "css"
    ];
    maturity = "stable";
    protocol = [
      "wayland"
      "xorg"
    ];
    toolkit = "gtk4";
  };
  greetd = {
    categories = [
      "greeter"
      "interface"
    ];
    family = "greetd";
    kind = "daemon";
    independent = true;
    engine = [ "rust" ];
    config = [ "toml" ];
    maturity = "stable";
    protocol = [
      "wayland"
      "xorg"
      "tty"
      "kms"
    ];
    toolkit = "none";
  };
  lemurs = {
    categories = [
      "greeter"
      "interface"
    ];
    kind = "terminal";
    independent = true;
    engine = [ "rust" ];
    config = [ "toml" ];
    maturity = "young";
    protocol = [
      "wayland"
      "xorg"
      "tty"
      "kms"
    ];
    toolkit = "ncurses";
  };
  lightdm = {
    categories = [
      "greeter"
      "interface"
    ];
    kind = "graphical";
    independent = true;
    engine = [ "c" ];
    config = [ "ini" ];
    maturity = "legacy";
    protocol = [
      "wayland"
      "xorg"
    ];
    toolkit = "gtk3";
  };
  ly = {
    categories = [
      "greeter"
      "interface"
    ];
    kind = "terminal";
    independent = true;
    engine = [ "zig" ];
    config = [ "ini" ];
    maturity = "young";
    protocol = [
      "wayland"
      "xorg"
      "tty"
      "kms"
    ];
    toolkit = "ncurses";
  };
  plasma-login-shell = {
    categories = [
      "greeter"
      "interface"
    ];
    family = "plasma";
    kind = "graphical";
    independent = false;
    engine = [
      "c++"
      "qml"
    ];
    config = [ "qml" ];
    maturity = "stable";
    protocol = [
      "wayland"
      "xorg"
    ];
    toolkit = "qt6";
  };
  regreet = {
    categories = [
      "greeter"
      "interface"
    ];
    family = "greetd";
    kind = "graphical";
    independent = true;
    engine = [ "rust" ];
    config = [
      "toml"
      "css"
    ];
    maturity = "stable";
    protocol = [
      "wayland"
      "xorg"
    ];
    toolkit = "gtk4";
  };
  sddm = {
    categories = [
      "greeter"
      "interface"
    ];
    family = "plasma";
    kind = "graphical";
    independent = true;
    engine = [ "c++" ];
    config = [
      "qml"
      "ini"
    ];
    maturity = "stable";
    protocol = [
      "wayland"
      "xorg"
    ];
    toolkit = "qt6";
  };
  tuigreet = {
    categories = [
      "greeter"
      "interface"
    ];
    kind = "terminal";
    independent = true;
    engine = [ "rust" ];
    config = [ "shell" ];
    maturity = "stable";
    protocol = [
      "wayland"
      "xorg"
      "tty"
      "kms"
    ];
    toolkit = "ncurses";
  };
}
