{
  config,
  lib,
  pkgs,
  ...
}:
let
  ctx = "multimedia";

  inherit (lib.options) mkOption mkDefault;
  inherit (config) dots;
  inherit (config.dots.active.user) context;

  packages = {
    tui = with pkgs; [ ];
    gui = with pkgs; [ ];
  };
in
{
  config = mkIf (elem ctx context) {

    environment = {
      systemPackages = with packages; if isMinimal then tui else tui ++ gui;
    };

    programs = { };

    services = {
      tailscale.enable = mkDefault true;
      openvscode-server.enable = mkDefault (elem "development" context);
    };
  };
}
