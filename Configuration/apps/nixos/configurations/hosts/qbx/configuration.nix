{
  imports = [
    ./core
    ./home
  ];

  dots = {
    interface.autologin = {
      enable = true;
      user = "craole";
    };

    users = {
      craole = {
        enable = true;
        display = "sddm";
        desktop = "gnome";
        manager = "hyprland";
        protocol = "wayland";
      };
    };
  };
}
