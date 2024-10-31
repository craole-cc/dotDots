{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
}:
let
  _mod = "applications";
in
{

  module = _args: {
    "${_mod}" =
      let
        _cfg = _args.user;
        _opt = _cfg.${_mod};
        inherit (lib.options) mkOption mkEnableOption mkPackageOption;
      in
      #| Application Modules
      # inherit ((import ./bat { inherit pkgs lib; }).module _args) bat;
      # btop = import ./btop { inherit pkgs lib args; };
      # dunst = import ./dunst { inherit pkgs lib args; };
      # firefox = import ./firefox { inherit pkgs lib args; };
      # git = import ./git { inherit pkgs lib args; };
      # helix = import ./helix { inherit pkgs lib args; };
      # hyprland = import ./hyprland { inherit pkgs lib args; };
      # microsoft-edge = import ./microsoft-edge { inherit pkgs lib args; };
      # rofi = import ./rofi { inherit pkgs lib args; };
      # waybar = import ./waybar { inherit pkgs lib args; };
      # inherit (bat.options args) bat;
      # inherit (btop.options args) btop;
      # inherit (dunst.options args) dunst;
      # inherit (firefox.options args) firefox;
      # inherit (git.options args) git;
      # inherit (helix.options args) helix;
      # inherit (hyprland.options args) hyprland;
      # inherit (microsoft-edge.options args) microsoft-edge;
      # inherit (rofi.options args) rofi;
      # inherit (waybar.options args) waybar;
      {
        # bat = mkOption { default = bat; };
        # inherit bat;
        # inherit host;
        # user = mkOption { default = user; };
        # host = mkOption { default = host; };
      };
  };
}
