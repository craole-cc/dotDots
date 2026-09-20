{
  host,
  lib,
  pkgs,
  user,
  ...
}: let
  guacamole = host.access.remote.guacamole or {};
  enable = guacamole.enable or false;
  desktopUser = guacamole.desktopUser or null;
  vncPort = guacamole.vncPort or 5900;
in
  lib.mkIf (enable && user.name == desktopUser) {
    systemd.user.services.wayvnc = {
      Unit = {
        Description = "WayVNC server for the current Hyprland session";
        After = [
          "graphical-session.target"
          "wayland-wm-env@hyprland.desktop.service"
        ];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "${pkgs.wayvnc}/bin/wayvnc --render-cursor 127.0.0.1:${toString vncPort}";
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  }
