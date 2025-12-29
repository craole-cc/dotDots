{
  host,
  lib,
  lix,
  pkgs,
  user,
  ...
}: let
  inherit (lix.modules.core) mkSudoRules;
  inherit (lix.attrsets.resolution) package;
in {
  home = {
    inherit (host) stateVersion;
    packages = with pkgs; (map (shell:
      package {
        inherit pkgs;
        target = shell;
      })
    (user.shells or []));
  };

  # wayland.windowManager = {
  #   hyprland.enable = user.interface.windowManager or null == "hyprland";
  #   sway.enable = user.interface.windowManager or null == "sway";
  #   river.enable = user.interface.windowManager or null == "river";
  #   labwc.enable = user.interface.windowManager or null == "labwc";
  #   wayfire.enable = user.interface.windowManager or null == "wayfire";
  # };

  imports = [
    # ./apps.nix
    ./atuin
    ./bash
    # ./firefox
    ./fonts.nix
    ./foot
    # ./freetube
    # ./ghostty
    ./helix
    ./home-manager
    ./mpv
    ./niri
    # ./noctula-shell
    ./nushell
    # ./obs
    # ./starship
    ./themes.nix
    # ./tinty # TODO: Not ready yet
    # ./vscode
    # ./zed
  ];
}
