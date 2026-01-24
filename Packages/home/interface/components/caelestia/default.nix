{
  lib,
  pkgs,
  locale,
  fonts,
  paths,
  keyboard,
  ...
}: let
  inherit (lib.modules) mkIf mkMerge;
  inherit (keyboard) mod;

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

  programs.${name} = mkMerge [
    (import ./cli {})
    (import ./settings {inherit locale fonts mkMerge paths keyboard;})
  ];

  services = mkMerge [
    {make.enable = false;}
  ];

  cfg = {
    inherit name kind programs services;
    enable = true; # TODO: Needs to be dynamic based on user choice
    home = {inherit packages;};
  };
in {
  config = mkIf cfg.enable (mkMerge [
    {inherit (cfg) programs home services;}
    (import ./hyprland.nix {inherit mod;})
  ]);
}
