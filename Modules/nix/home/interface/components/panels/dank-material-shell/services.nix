{
  config,
  lix,
  sync,
}: let
  inherit (lix.modules.construction) mkForce;
in {
  user = {
    # DMS 1.6.3 does not emit the readiness notification newer modules expect.
    services.dms.Service = {
      Type = mkForce "simple";
      NotifyAccess = mkForce "none";
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
      ];
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
