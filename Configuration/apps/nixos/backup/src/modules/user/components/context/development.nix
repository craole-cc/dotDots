{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config) dot;
  # inherit (dots.info.host) context isMinimal;
  inherit (config.dot.active)

  packages = {
    tui = with pkgs; [ helix ];
    gui = with pkgs; [ vscode-fhs ];
  };
in
with lib;
{
  config = mkIf (elem "development" context) {

    environment = {
      systemPackages = with packages; if isMinimal then tui else tui ++ gui;
    };

    programs = {
      direnv = {
        enable = true;
        silent = true;
      };
      git = {
        enable = true;
        lfs.enable = true;
      };
      lazygit.enable = true;
    };

    services = {
      gnome.gnome-keyring.enable = true;
    };
  };
}
