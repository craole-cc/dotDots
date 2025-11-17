{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.programs.brave;
in {
  options.programs.brave = {
    enable = mkEnableOption "Brave Browser";
  };

  imports = [
    ./settings.nix
    ./extensions.nix
    ];

  config = mkIf cfg.enable {
    programs.chromium = {
      enable = true;
      package = pkgs.brave
    };
  };
}
