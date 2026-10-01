{
  host,
  lib,
  pkgs,
  ...
}: let
  enable = builtins.elem "control-plane" (host.functionalities or []);

  launcher = pkgs.writeShellApplication {
    name = "desktop-commander-remote";
    runtimeInputs = [pkgs.nodejs];
    text = ''
      exec npx -y @wonderwhy-er/desktop-commander@0.2.52 remote
    '';
  };
in
  lib.mkIf enable {
    home.packages = [pkgs.tmux];

    systemd.user.services.desktop-commander-remote = {
      Unit = {
        Description = "Desktop Commander Remote control plane";
        After = ["network-online.target"];
        Wants = ["network-online.target"];
      };
      Service = {
        ExecStart = "${launcher}/bin/desktop-commander-remote";
        Restart = "always";
        RestartSec = 10;
      };
      Install.WantedBy = ["default.target"];
    };
  }
