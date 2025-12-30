{
  host,
  lib,
  ...
}: {
  settings =
    {}
    // import ./output.nix {inherit host lib;}
    // import ./input.nix {inherit host lib;}
    # // import ./environment.nix {inherit host lib;}
    # // import ./startup.nix
    // import ./core.nix
    // import ./rules.nix {inherit lib;}
    // {};

  # systemd = {
  #   enable = true;
  #   variables = [ "-all" ];
  #   extraCommands = [
  #     "systemctl --user stop graphical-session.target"
  #     "systemctl --user start hyprland-session.target"
  #   ];
  # };
}
