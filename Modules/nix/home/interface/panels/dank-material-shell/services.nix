{
  config,
  lix,
  sync,
}: let
  inherit (lix.modules.construction) mkForce;
  inherit (lix.filesystem.construction) concatPath;

  mkPath = root: stem:
    concatPath {
      root = config.xdg.${root};
      stem = ["dms" stem];
    };
in {
  user = {
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
        (mkPath "configHome" "settings.json")
        (mkPath "stateHome" "session.json")
        "%h/.config/foot/dank-colors.ini"
        (mkPath "cacheHome" "dms-colors.json")
        (mkPath "configHome" "palette-accent.hex")
      ];
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
