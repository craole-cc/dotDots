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

  cfg = userApplicationConfig rec {
    inherit user pkgs config;
    name = "vicinae";
    kind = "launcher";
    # command = "";
    customCommand = name;
    extraProgramConfig = mkMerge [(import ./settings.nix)];
    debug = false;
  };
  payload = mkMerge [
    {inherit (cfg) programs home;}
    (import ./hyprland.nix {inherit lib config;})
  ];
in {
  config = lib.mkMerge (mkStaged {
    inherit top payload;
    condition = cfg.enable;
  });
}
