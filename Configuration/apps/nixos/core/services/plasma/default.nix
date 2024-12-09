{ specialArgs, pkgs, ... }:
if specialArgs.ui.env == "plasma" then
  {
    imports=[./packages.nix];
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
        login = {
          enableKwallet = true;
          forceRun = true;
        };
        sddm = {
          enableKwallet = true;
          forceRun = true;
        };
      };
    };

    environment.plasma6.excludePackages = with pkgs; [ kate ];

  }
else
  { }
