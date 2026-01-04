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
      # (import ./input.nix)
      # (import ./themes.nix)
    ];
    debug = false;
  };
in {
  config = mkIf cfg.enable {
    inherit (cfg) programs home;
    # home =
    #   cfg.home
    #   // (with cfg; {
    #     shellAliases."launch_${name}" = "${name} open";
    #   });
  };
}
#TODO: Update the userApplicationConfig to take the launcher command
