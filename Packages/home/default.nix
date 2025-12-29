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
    ./common
    ./apps.nix

    ./atuin
    ./bash
    # ./firefox
    ./foot
    ./freetube
    ./ghostty
    ./helix
    ./mpv
    ./niri
    ./noctula-shell
    ./nushell
    ./obs
    # ./tinty # TODO: Not ready yet
    ./vscode
    # ./zed
    ./themes.nix
  ];
}
