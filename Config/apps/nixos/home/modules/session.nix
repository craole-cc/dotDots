{...}: {
  services.xserver.displayManager = {
    defaultSession = "none+qtile";
    autoLogin = {
      enable = true;
      user = "craole";
    };
  };
}
