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
  inherit (lib.modules) mkMerge;
  inherit (lix.applications.generators) userApplicationConfig;

  cfg = userApplicationConfig {
    inherit user pkgs config;
    name = "fuzzel";
    kind = "launcher";
    extraProgramConfig = mkMerge [
      {
        settings.main = {
          terminal = "$TERMINAL"; # TODO Use defaults defined in lib
          layer = "overlay";
        };
      }
      # (import ./settings.nix)
      # (import ./input.nix)
      # (import ./themes.nix)
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
