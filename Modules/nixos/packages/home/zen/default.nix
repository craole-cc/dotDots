{
  #TODO: use the flake inputs overlay
  config,
  lib,
  inputs,
  system,
  ...
}:

let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.programs.brave;
in
{
  options.programs.brave = {
    enable = mkEnableOption "Zen Browser";
  };

  config = mkIf cfg.enable {
    home.packages = [ inputs.zen-browser.packages."${system}".specific ];
  };
}
