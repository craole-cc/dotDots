{
  config,
  lix,
  user,
  ...
}: let
  inherit (lix) toolkit;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;
  inherit (lix.lists.predicates) elem;
  context = mkContext {
    inherit config;
    dom = "communication";
    mod = "google";
  };
  sync = toolkit.write.bin "google-calendar" ''
    exec ${toolkit.binaries.python3} ${./google-calendar.py} ${toolkit.binaries.vdirsyncer} "$@"
  '';
in
  mkConfig {
    inherit context;
    options.enable = mkEnable {
      inherit context;
      condition = elem "thunderbird" (user.packages.communication or []);
    };
    outputs = {
      home.packages = [toolkit.packages.khal toolkit.packages.vdirsyncer sync];
      xdg.configFile."khal/config".text = ''
        [calendars]
        [[google]]
        path = ${config.xdg.dataHome}/calendars/google/*
        type = discover
        readonly = True
        [locale]
        timeformat = %H:%M
        dateformat = %Y-%m-%d
        longdateformat = %Y-%m-%d
        datetimeformat = %Y-%m-%d %H:%M
        longdatetimeformat = %Y-%m-%d %H:%M
        [default]
        timedelta = 30d
      '';
      programs.thunderbird = {
        enable = true;
        package = toolkit.packages.thunderbird;
        profiles.google = {
          isDefault = true;
          settings."calendar.timezone.local" = "America/Jamaica";
        };
      };
      accounts.email.accounts.google = {
        primary = true;
        address = "iamcraole@gmail.com";
        realName = user.description;
        userName = "iamcraole@gmail.com";
        flavor = "gmail.com";
        imap.authentication = "xoauth2";
        smtp.authentication = "xoauth2";
        thunderbird.enable = true;
      };
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
