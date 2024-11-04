{
  config,
  lib,
  pkgs,
  ...
}:
let
  ctx = "multimedia";

  inherit (lib.options) mkOption mkDefault;
  inherit (config) dot;
  inherit (config.dots.active.user) context;

  packages = {
    tui = with pkgs; [ ];
    gui = with pkgs; [ ];
  };
in
{

  options.dot
  config = mkIf (elem ctx context) {

    users. = {
      systemPackages = with packages; if isMinimal then tui else tui ++ gui;
    };

    programs = { };

    services = {
      tailscale.enable = mkDefault true;
    };
  };
}
