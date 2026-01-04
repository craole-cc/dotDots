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
    # command = "";
    extraProgramConfig = mkMerge [
      (import ./settings.nix)
    ];
    debug = false;
  };
in {
  config = mkIf cfg.enable {
    inherit (cfg) programs home;
  };
}
#TODO: Update the userApplicationConfig to take the launcher command
