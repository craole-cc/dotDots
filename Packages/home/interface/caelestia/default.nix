{
  lib,
  pkgs,
  city,
  fonts,
  mkMerge,
  paths,
  keyboard,
  ...
}: let
  inherit (lib.modules) mkIf;

  name = "caelestia";
  kind = "bar";

  programs.${name} = mkMerge [
    (import ./cli {})
    (import ./settings {inherit city fonts mkMerge paths keyboard;})
  ];

  packages = with pkgs; [
    aubio
    brightnessctl
    ddcutil
    glibc
    libgcc
    cava
    lm_sensors
  ];

  cfg = {
    inherit name kind programs;
    enable = true;
    home = {inherit packages;};
  };
in {
  config = mkIf cfg.enable (mkMerge [
    {inherit (cfg) programs home;}
    # (import ./hyprland.nix {inherit lib config;})
  ]);
}
