_: {
  cinnamon = {
    family = "cinnamon";
    categories = [
      "interface"
      "notifier"
    ];
    protocol = [ "xorg" ];
    independent = false;
    engine = [ "c" ];
    config = [
      "javascript"
      "css"
    ];
    maturity = "stable";
  };
  cosmic-notifications = {
    family = "cosmic";
    categories = [
      "interface"
      "notifier"
    ];
    protocol = [ "wayland" ];
    independent = false;
    engine = [ "rust" ];
    config = [
      "ron"
      "css"
    ];
    maturity = "young";
  };
  deadd-notification-center = {
    categories = [
      "interface"
      "notifier"
    ];
    protocol = [ "xorg" ];
    independent = true;
    engine = [ "haskell" ];
    config = [ "css" ];
    maturity = "young";
  };
  dms-shell = {
    categories = [
      "interface"
      "notifier"
    ];
    family = "dms";
    protocol = [ "wayland" ];
    independent = true;
    engine = [ "go" ];
    config = [ "qml" ];
    maturity = "young";
  };
  dunst = {
    categories = [
      "interface"
      "notifier"
    ];
    protocol = [
      "wayland"
      "xorg"
    ];
    independent = true;
    engine = [ "c" ];
    config = [ "ini" ];
    maturity = "stable";
  };
  fnott = {
    categories = [
      "interface"
      "notifier"
    ];
    protocol = [ "wayland" ];
    independent = true;
    engine = [ "c" ];
    config = [ "ini" ];
    maturity = "stable";
  };
  gnome-shell = {
    categories = [
      "interface"
      "notifier"
    ];
    family = "gnome";
    protocol = [ "wayland" ];
    independent = false;
    engine = [
      "c"
      "javascript"
    ];
    config = [
      "javascript"
      "css"
    ];
    maturity = "stable";
  };
  mako = {
    categories = [
      "interface"
      "notifier"
    ];
    protocol = [ "wayland" ];
    independent = true;
    engine = [ "c" ];
    config = [ "ini" ];
    maturity = "stable";
  };
  notification-daemon = {
    categories = [
      "interface"
      "notifier"
    ];
    protocol = [ "xorg" ];
    independent = false;
    engine = [ "c" ];
    config = [ "ini" ];
    maturity = "legacy";
  };
  plasmashell = {
    categories = [
      "interface"
      "notifier"
    ];
    family = "plasma";
    protocol = [ "wayland" ];
    independent = false;
    engine = [
      "c++"
      "qml"
    ];
    config = [
      "qml"
      "javascript"
    ];
    maturity = "stable";
  };
  xfce4-notifyd = {
    categories = [
      "interface"
      "notifier"
    ];
    family = "xfce";
    protocol = [ "xorg" ];
    independent = false;
    engine = [ "c" ];
    config = [
      "rc"
      "css"
    ];
    maturity = "stable";
  };
}
