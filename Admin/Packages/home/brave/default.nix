{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  dom = "apps";
  mod = "brave";
  cfg = config.${dom}.${mod};
in {
  options.${dom}.${mod} = {
    enable = mkEnableOption "Brave Browser";
  };

  imports = [
    ./settings.nix
    ./extensions.nix
    ];

  config = mkIf cfg.enable {
    programs.chromium = {
      enable = true;
      package = pkgs.brave;
    };
  };
}
