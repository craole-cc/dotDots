{ config, ... }:
let
  inherit (config.DOTS) Active;
  inherit (Active.host) contextAllowed;
  inherit (config.DOTS.Libraries.fetchers) githubEmail;
in
{
  # imports = [ ./settings ];

  DOTS.Users.craole = {
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

    context = contextAllowed;
    # shell = pkgs.nushell;
    apps = {
      # git = rec {
      #   name = "Craole";
      #   email = githubEmail {
      #     user = name;
      #     sha256 = "KYcIRoD70dqK2SVHAXVUpCYfpDNZ3v2GN7pd0J4PobI=";
      #   };
      # };
      bat.enable = true;
      btop.enable = true;
      firefox = {
        isPrimary = false;
        edition = "dev";
      };
    };
  };
}
