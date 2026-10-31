{
  config,
  lix,
  user,
  ...
}: let
  inherit (lix.toolkit) write binaries packages;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;
  inherit (lix.lists.predicates) elem;
  context = mkContext {
    inherit config;
    dom = "communication";
    mod = "khal";
  };
  sync = write.rust {
    name = "google-calendar";
    src = ./google-calendar.rs;
    inputs = with packages; [vdirsyncer];
    arguments = [binaries.vdirsyncer];
  };
in
  mkConfig {
    inherit context;
    options.enable = mkEnable {
      inherit context;
      condition =
        elem "khal" (user.packages.communication or [])
        || (user.interface.dms.settings.calendarBackend or "") == "khal";
    };
    outputs = {
      home.packages = with packages; [khal vdirsyncer sync];
      xdg.configFile."khal/config".text = ''
        [calendars]
        [[google]]
        path = ${config.xdg.dataHome}/calendars/google/*
        type = discover
        readonly = False
        [locale]
        timeformat = %H:%M
        dateformat = %Y-%m-%d
        longdateformat = %Y-%m-%d
        datetimeformat = %Y-%m-%d %H:%M
        longdatetimeformat = %Y-%m-%d %H:%M
        [default]
        timedelta = 30d
      '';

      systemd.user = {
        services.google-calendar = {
          Unit = {
            Description = "Synchronise Google Calendar for Khal";
            ConditionPathExists = "${config.xdg.stateHome}/vdirsyncer/google.ready";
          };
          Service = {
            Type = "oneshot";
            ExecStart = "${sync}/bin/google-calendar sync";
            UMask = "0077";
          };
        };
        timers.google-calendar = {
          Unit.Description = "Synchronise Google Calendar every five minutes";
          Timer = {
            OnCalendar = "*:0/5";
            Persistent = true;
            RandomizedDelaySec = 30;
          };
          Install.WantedBy = ["timers.target"];
        };
      };
    };
  }
