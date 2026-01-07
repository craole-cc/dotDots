{
  lib,
  pkgs,
  host,
  config,
  ...
}: let
  inherit (lib.modules) mkIf mkMerge;
  name = "caelestia";
  kind = "bar";
  city = host.localization.city or "Mandeville, Jamaica";
  programs.${name} = mkMerge [
    (import ./cli {})
    (import ./settings {inherit mkMerge city;})
  ];
  packages = with pkgs; [
    aubio
    brightnessctl
    ddcutil
    glibc
    libgcc
    cava
    lm_sensors
    thunar
  ];

  cfg = {
    inherit name kind programs;
    enable = true;
    home = {inherit packages;};
  };
in {
  config = mkIf cfg.enable mkMerge [
    {inherit (cfg) programs home;}
    # (import ./hyprland.nix {inherit lib config;})
  ];
}
