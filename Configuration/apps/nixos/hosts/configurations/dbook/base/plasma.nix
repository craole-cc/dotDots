{
  services = {
    displayManager = {
      autoLogin = {
        enable = true;
        user = "craole";
      };
      sddm = {
        enable = true;
        wayland.enable = true;
      };
    };

    desktopManager = {
      plasma6.enable = true;
    };
  };

  security = {
    pam.services = {
      login = {
        enableKwallet = true;
        # forceRun = true;
      };
      sddm = {
        enableKwallet = true;
        # forceRun = true;
      };
    };
  };
}
