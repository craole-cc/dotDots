{pkgs, ...}: let
  theme = nightDiamond;
  variant = "red";

  # afterglow = let
  #   package = pkgs.afterglow-cursors-recolored;
  # in {
  #   purple = {
  #     inherit package;
  #     name = "Graphite-Recolored-Purple";
  #   };
  #   blue = {
  #     inherit package;
  #     name = "Graphite-Recolored-Blue";
  #   };
  # };

  nightDiamond = let
    package = pkgs.nightdiamond-cursors;
  in {
    red = {
      inherit package;
      name = "NightDiamond-Red";
    };
    blue = {
      inherit package;
      name = "NightDiamond-Blue";
    };
  };
in {
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    inherit (theme."${variant}") package name;
    size = 20;
  };
}
# packagesackages = with pkgs; [bibata-cursors-translucent afterglow-cursors-recolored everforest-cursors];
