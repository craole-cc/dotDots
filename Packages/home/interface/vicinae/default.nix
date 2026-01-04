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
    name = "vicinae";
    kind = "launcher";
    extraProgramConfig = mkMerge [
      {
        systemd.enable = true;
      }
      # (import ./settings.nix)
      # (import ./input.nix)
      # (import ./themes.nix)
    ];
    debug = false;
  };
in {
  config = mkIf cfg.enable {
    inherit (cfg) programs home;
  };
}
