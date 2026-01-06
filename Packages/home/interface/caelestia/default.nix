{
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf mkMerge;

  cfg = rec {
    name = "caelestia";
    kind = "bar";
    enable = true;
    programs.${name} = mkMerge [
      (import ./cli {})
      (import ./settings {inherit mkMerge;})
    ];
    packages = with pkgs; [
      aubio
      brightnessctl
      ddcutil
      glibc
      libgcc
      lm_sensors
    ];
    home = {inherit packages;};
  };
in {
  config = mkIf cfg.enable {
    inherit (cfg) programs home;
  };
}
