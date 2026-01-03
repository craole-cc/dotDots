{
  config,
  lib,
  lix,
  user,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf mkMerge;
  inherit (lix.applications.generators) userApplicationConfig;

  cfg = userApplicationConfig {
    inherit user pkgs config;
    name = "noctalia-shell";
    kind = "bar";
    resolutionHints = ["noctalia"];
    requiresWayland = true;
    extraProgramConfig = mkMerge [
      (import ./bar.nix)
      (import ./launcher.nix)
    ];
    debug = false;
  };
in {
  config = mkIf cfg.enable {
    inherit (cfg) home programs;
  };
}
