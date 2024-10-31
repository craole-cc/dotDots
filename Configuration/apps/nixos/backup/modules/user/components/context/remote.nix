{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config) dots;
  inherit (dots.info.host) context isMinimal;

  packages = {
    tui = with pkgs; [ ];
    gui = with pkgs; [ ];
  };
in
with lib;
{
  config = mkIf (elem "remote" context) {

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
