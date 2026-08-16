{
  config,
  lib,
  lix,
  user,
  pkgs,
  top,
  ...
}: let
  inherit (lix.modules.core.staging) mkStaged;
  inherit (lib.modules) mkIf mkMerge;
  inherit (lix.applications.generators) userApplicationConfig;

  cfg = userApplicationConfig {
    inherit user pkgs config;
    name = "ghostty";
    kind = "terminal";
    extraProgramConfig = mkMerge [
      (import ./general.nix)
      (import ./input.nix)
      (import ./themes.nix)
    ];
    debug = false;
  };
  payload = {inherit (cfg) programs home;};
in {
  config = lib.mkMerge (mkStaged {
    inherit top payload;
    condition = cfg.enable;
  });
}
