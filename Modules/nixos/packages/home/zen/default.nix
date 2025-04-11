{
  #TODO: use the flake inputs overlay
  config,
  lib,
  inputs,
  system,
  ...
}:

let
  # inherit (osConfig) inputs system;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.programs.zen-browser;
in
{
  options.programs.zen-browser = {
    enable = mkEnableOption "Zen Browser";
  };

  config = mkIf cfg.enable {
    home.packages = [ inputs.zen-browser.packages."${system}".twilight ];
  };
}
