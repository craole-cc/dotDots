{
  config,
  lix,
  pkgs,
  quickshell,
  sync,
}: let
  inherit (lix.modules.construction) mkForce;
  dcalSession = pkgs.writeShellApplication {
    name = "dcal-session";
    runtimeInputs = [pkgs.dux-calendar quickshell.package];
    text = "exec dcal run --session --hidden";
  };
in {
  user = {
    # DMS 1.6.3 does not emit the readiness notification newer modules expect.
    services.dms.Service = {
      Type = mkForce "simple";
      NotifyAccess = mkForce "none";
    };

    services.dcal = {
      Unit = {
        Description = "Dux Calendar";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "${dcalSession}/bin/dcal-session";
        Restart = "on-failure";
        RestartSec = "2";
        Slice = "app.slice";
      };
      Install.WantedBy = ["graphical-session.target"];
    };

    services.dotdots-foot-dms-theme-reload = {
      Unit = {
        Description = "Apply DMS appearance to desktop and terminals";
        StartLimitIntervalSec = 0;
      };
      Service = {
        Type = "oneshot";
        ExecStart = sync;
      };
      Install.WantedBy = ["graphical-session.target"];
    };

    paths.dotdots-foot-dms-theme-reload = {
      Unit.Description = "Watch DMS appearance settings and terminal palettes";
      Path.PathChanged = [
        "${config.xdg.configHome}/dms/settings.json"
        "${config.xdg.stateHome}/dms/session.json"
        "%h/.config/foot/dank-colors.ini"
        "${config.xdg.configHome}/dms/palette-accent.hex"
      ];
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
