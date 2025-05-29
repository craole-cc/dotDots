{
  config,
  lib,
  pkgs,
  ...
}:
let
  ctx = "multimedia";

  inherit (lib.options) mkDefault;
  inherit (config.dots.active.user) context;

  packages = {
    tui = with pkgs; [ ];
    gui = with pkgs; [ ];
  };
in
{
  # options.dot
  config = lib.mkIf (lib.elem ctx context) {
    users = {
      systemPackages = with packages; if isMinimal then tui else tui ++ gui;
    };

    programs = { };

    services = {
      tailscale.enable = mkDefault true;
    };
  };
}
