{lib, ...}: let
  inherit (lib.modules) mkIf mkMerge;

  cfg = rec {
    name = "caelestia";
    kind = "bar";
    enable = true;
    programs.${name} = mkMerge [
      (import ./cli {})
      (import ./settings {inherit mkMerge;})
    ];
    home = {};
  };
in {
  config = mkIf cfg.enable {
    inherit (cfg) programs home;
  };
}
