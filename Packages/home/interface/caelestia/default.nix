{
  config,
  lib,
  lix,
  user,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf mkMerge;
  # inherit (lix.applications.generators) userApplicationConfig;

  # cfg = userApplicationConfig {
  #   inherit user pkgs config;
  #   name = "caelestia";
  #   kind = "bar";
  #   extraProgramConfig = mkMerge [
  #     (import ./cli.nix {})
  #     # (import ./bar.nix)
  #     # (import ./themes.nix)
  #   ];
  #   debug = true;
  # };

  cfg = rec {
    name = "caelestia";
    kind = "bar";
    enable = true;
    programs.${name} = mkMerge [
      (import ./cli.nix {})
      (import ./bar.nix {})
      # (import ./settings.nix {inherit pkgs;})
    ];
    home = {};
  };
in {
  config = mkIf cfg.enable {
    inherit (cfg) programs home;
  };
}
