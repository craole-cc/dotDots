{
  lib,
  pkgs,
  locale,
  style,
  paths,
  keyboard,
  ...
}: let
  inherit (lib.modules) mkIf mkMerge mkForce;
  inherit (keyboard) mod vimKeybinds;
  inherit (style) fonts;
  name = "caelestia";
  kind = "bar";

  packages = with pkgs; [
    aubio
    brightnessctl
    ddcutil
    glibc
    libgcc
    cava
    lm_sensors
  ];
  enable = true; # TODO: Needs to be dynamic based on user choice
  programs = {
    ${name} = mkMerge [
      {inherit enable;}
      (import ./cli {})
      (import ./settings {inherit locale fonts mkMerge paths vimKeybinds;})
    ];
  };

  services = {
    mako.enable = mkForce false;
  };

  cfg = {
    inherit enable name kind programs services;
    home = {inherit packages;};
  };
in {
  config = mkIf cfg.enable (mkMerge [
    {
      inherit (cfg) programs home services;
      systemd.user.services.caelestia = {
        Unit.ConditionEnvironment = [
          "|XDG_CURRENT_DESKTOP=Hyprland"
          "|XDG_CURRENT_DESKTOP=niri"
        ];
      };
    }
    (import ./hyprland.nix {inherit mod;})
  ]);
}
