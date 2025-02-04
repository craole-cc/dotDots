{
  imports = [
    ./core
    ./custom
    ./desktop
    ./libraries
    # ./programs
    # ./services
    ./users
  ];

  dots = {
    desktop.login = {
      manager = "sddm";
      automatically = true;
      user = "craole";
    };

    users = {
      craole = {
        enable = true;
        # display = "sddm";
        # desktop = "gnome";
        # manager = "hyprland";
        # protocol = "wayland";
      };
      qyatt.enable = true;
      cc = {
        enable = true;
        isSystemUser = true;
      };
    };
  };
}
