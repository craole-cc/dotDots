# interface/environment/cosmic/common.nix
{
  config,
  lib,
  top,
  ...
}: let
  inherit (lib.modules) mkIf;
  cfg = config.${top}.interface;
in {
  config = mkIf (cfg.de == "cosmic") {
    services = {
      desktopManager.cosmic = {
        enable = true;
        showExcludedPkgsWarning = false;
      };

      # displayManager = {
      #   cosmic-greeter.enable = cfg.dm == "cosmic-greeter";
      #   sddm = mkIf (cfg.dm == "sddm") {
      #     enable = true;
      #     wayland.enable = cfg.dp == "wayland";
      #   };
      # };
    };
  };
}
