{ config, pkgs, ... }:
{
  # imports = [ ./settings ];

  config.dot = {
    users.craole = {
      description = "Craig 'Craole' Cole";
      id = 1551;
      hashedPassword = "$y$j9T$2/KP4Wdc085m.udldFeHA0$C8K1uEH1hBwM0SHXg5l2Rnvy3jGEnq/p0MN7O7ZIXw3";

      desktop = {
        manager = "hyprland";
        server = "wayland";
      };

      display = {
        autoLogin = true;
        manager = "sddm";
      };

      context = config.dot.active.host.contextAllowed;
      # # shell = pkgs.nushell;
      applications = {
        git = {
          name = "Craole";
          email = "32288735+Craole@users.noreply.github.com";
        };

        bat.enable = true;
        btop.enable = true;
      };
    };
    # programs.git.lfs.skipSmudge = true;
  };
}
