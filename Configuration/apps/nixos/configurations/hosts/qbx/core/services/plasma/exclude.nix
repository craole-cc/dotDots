{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf mkDefault;
  cfg = config.dots.services.plasma;
in
{
  config = mkIf cfg.enable {
    environment.plasma6.excludePackages = with pkgs; [
    ];
  };
}
