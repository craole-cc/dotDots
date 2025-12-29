{
  host,
  lib,
  lix,
  pkgs,
  user,
  ...
}: let
  inherit (lib.attrsets) attrValues filterAttrs mapAttrs optionalAttrs attrByPath;
  inherit (lib.lists) any concatMap elem head optionals;
  inherit (lib.modules) mkDefault;
  inherit (lix.modules.core) mkSudoRules;
  inherit (lix.attrsets.resolution) package;
  inherit (lix.applications.firefox) zenVariant;
  inherit (lix.lists.predicates) isIn;
in {
  home = {
    inherit (host) stateVersion;
    packages = with pkgs; (map (shell:
      package {
        inherit pkgs;
        target = shell;
      })
    user.shells);
  };

  # programs = {
  #   zsh.enable = mkDefault (elem "zsh" (user.shells or []));
  #   fish.enable = mkDefault (elem "fish" (user.shells or []));
  #   nushell.enable = mkDefault (elem "nushell" (user.shells or []));
  # };

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
    # ./niri
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
