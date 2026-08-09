{
  config,
  lib,
  lix,
  user,
  pkgs,
  top,
  ...
}: let
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
in {
config = lib.mkMerge [
    (mkIf cfg.enable {inherit (cfg) programs home;})
    {${top}.output = mkIf cfg.enable {inherit (cfg) programs home;};}
  ];
}
