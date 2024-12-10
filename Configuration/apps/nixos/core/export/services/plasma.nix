{ specialArgs, ... }:
if specialArgs.ui.env == "plasma" then
  {
    services = {
      desktopManager = {
        plasma6.enable = true;
      };
      displayManager.sddm = {
        enable = true;
        wayland.enable = true;
      };
    };

    security = {
      pam.services = {
        login.enableKwallet = true;
        sddm.enableKwallet = true;
      };
    };
  }
else
  { }
