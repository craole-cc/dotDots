{
  mkAliasFamily,
  mergeDisjoint,
  mkSource,
  ...
}: {
  nh = mkSource {
    categories = ["system" "scripting"];
    description = "Nix helper";
    aliases = mkAliasFamily "nh" {
      s = {
        args = ["os" "switch" "--show-trace"];
        description = "switch NixOS configuration and print the completion time";
        after = [["date"]];
      };
      r = {
        args = ["os" "repl"];
        description = "open the NixOS configuration REPL";
      };
      c = {
        args = ["clean" "all"];
        description = "clean all Nix profiles and store paths";
      };
    };
  };

  procps = mkSource {
    categories = ["system" "scripting"];
    description = "pkill, pgrep, ps, top, and related process tools";
    discover = true; #? pkill, pgrep, ps, top, ...
    exe = "pkill";
    aliases = mergeDisjoint [
      (mkAliasFamily "free" {
        h = {
          args = ["-h"];
          description = "show memory usage in human-readable sizes";
        };
      })
      (mkAliasFamily "pidof" {
        s = {
          args = ["-s"];
          description = "print a single matching process ID";
        };
      })
      (mkAliasFamily "top" {
        Batch = {
          args = ["-b" "-n" "1"];
          description = "print a single non-interactive snapshot of top";
        };
      })
      (mkAliasFamily "uptime" {
        Pretty = {
          args = ["--pretty"];
          description = "show uptime in a human-readable form";
        };
      })
      (mkAliasFamily "pgrep" {
        f = {
          args = ["-f"];
          description = "find processes by matching the full command line";
        };
        a = {
          args = ["-a"];
          description = "show matching process IDs with their full command lines";
        };
        c = {
          args = ["-c"];
          description = "count matching processes";
        };
        l = {
          args = ["-l"];
          description = "show matching process IDs with process names";
        };
        u = {
          args = ["-u"];
          description = "find processes owned by a caller-specified user";
        };
        x = {
          args = ["-x"];
          description = "find processes matching the exact name";
        };
      })
      (mkAliasFamily "pkill" {
        f = {
          args = ["-f"];
          description = "signal processes whose full command lines match";
        };
        HUP = {
          args = ["-HUP"];
          description = "send SIGHUP to matching processes";
        };
        HUPx = {
          args = ["-HUP" "-x"];
          description = "send SIGHUP to processes matching the exact name";
        };
        "9" = {
          args = ["-9"];
          description = "force-kill matching processes";
        };
        "9x" = {
          args = ["-9" "-x"];
          description = "force-kill processes matching the exact name";
        };
        USR1 = {
          args = ["-USR1"];
          description = "send SIGUSR1 to matching processes";
        };
        USR1x = {
          args = ["-USR1" "-x"];
          description = "send SIGUSR1 to processes matching the exact name";
        };
        USR2 = {
          args = ["-USR2"];
          description = "send SIGUSR2 to matching processes";
        };
        USR2x = {
          args = ["-USR2" "-x"];
          description = "send SIGUSR2 to processes matching the exact name";
        };
        x = {
          args = ["-x"];
          description = "signal processes matching the exact name";
        };
      })
      (mkAliasFamily "ps" {
        aux = {
          args = ["aux"];
          description = "list all processes with user and resource columns";
        };
        Cpu = {
          args = ["aux" "--sort=-%cpu"];
          description = "list processes sorted by CPU usage, highest first";
        };
        ef = {
          args = ["-ef"];
          description = "list all processes in full format";
        };
        Mem = {
          args = ["aux" "--sort=-%mem"];
          description = "list processes sorted by memory usage, highest first";
        };
      })
      (mkAliasFamily "watch" {
        d = {
          args = ["--differences"];
          description = "repeat a command and highlight changes between runs";
        };
        n = {
          args = ["-n"];
          description = "repeat a command at a caller-specified interval in seconds";
        };
      })
    ];
  };

  systemd = mkSource {
    categories = ["system" "scripting"];
    description = "systemctl, journalctl, and related systemd tools";
    discover = true; #? systemctl, journalctl, ...
    exe = "systemctl";
    aliases = mergeDisjoint [
      (mkAliasFamily "systemd-analyze" {
        aliasPrefix = "systemdAnalyze";
        Blame = {
          args = ["blame"];
          description = "list units by startup time";
        };
        Verify = {
          args = ["verify"];
          description = "check unit files for errors";
        };
      })
      (mkAliasFamily "systemd-run" {
        aliasPrefix = "systemdRun";
        User = {
          args = ["--user"];
          description = "run a command as a transient current-user unit";
        };
      })
      (mkAliasFamily "journalctl" {
        Boot = {
          args = ["--boot"];
          description = "show journal entries from the current boot";
        };
        Err = {
          args = ["--boot" "--priority=err"];
          description = "show errors and worse from the current boot";
        };
        Follow = {
          args = ["--follow"];
          description = "follow new journal entries as they arrive";
        };
        Since = {
          args = ["--since"];
          description = "show journal entries since a caller-specified time";
        };
        Unit = {
          args = ["--unit"];
          description = "show journal entries for a caller-specified unit";
        };
        User = {
          args = ["--user"];
          description = "show journal entries for the current user";
        };
        UserUnit = {
          args = ["--user" "--unit"];
          description = "show journal entries for a caller-specified user unit";
        };
      })
      (mkAliasFamily "systemctl" {
        Cat = {
          args = ["cat"];
          description = "show a unit file and its drop-ins";
        };
        DaemonReload = {
          args = ["daemon-reload"];
          description = "reload systemd manager configuration";
        };
        DisableNow = {
          args = ["disable" "--now"];
          description = "disable a unit and stop it immediately";
        };
        EnableNow = {
          args = ["enable" "--now"];
          description = "enable a unit and start it immediately";
        };
        Failed = {
          args = ["--failed"];
          description = "list failed units";
        };
        Restart = {
          args = ["restart"];
          description = "restart a unit";
        };
        Start = {
          args = ["start"];
          description = "start a unit";
        };
        Status = {
          args = ["status"];
          description = "show a unit's status";
        };
        Stop = {
          args = ["stop"];
          description = "stop a unit";
        };
        User = {
          args = ["--user"];
          description = "manage the current user's systemd services";
        };
        UserR = {
          args = ["--user" "reload"];
          description = "reload a current-user systemd service";
        };
        UserDaemonReload = {
          args = ["--user" "daemon-reload"];
          description = "reload the current user's systemd manager configuration";
        };
        UserDisableNow = {
          args = ["--user" "disable" "--now"];
          description = "disable a current-user unit and stop it immediately";
        };
        UserEnableNow = {
          args = ["--user" "enable" "--now"];
          description = "enable a current-user unit and start it immediately";
        };
        UserFailed = {
          args = ["--user" "--failed"];
          description = "list failed current-user units";
        };
        UserRestart = {
          args = ["--user" "restart"];
          description = "restart a current-user unit";
        };
        UserStart = {
          args = ["--user" "start"];
          description = "start a current-user unit";
        };
        UserStatus = {
          args = ["--user" "status"];
          description = "show a current-user unit's status";
        };
        UserStop = {
          args = ["--user" "stop"];
          description = "stop a current-user unit";
        };
      })
    ];
  };

  util-linux = mkSource {
    categories = ["system" "scripting"];
    description = "mount, lsblk, flock, logger, and related system utilities";
    discover = true; #? mount, lsblk, flock, logger, ...
    exe = "mount";
    aliases = mergeDisjoint [
      (mkAliasFamily "hexdump" {
        C = {
          args = ["-C"];
          description = "show canonical hex and ASCII output";
        };
      })
      (mkAliasFamily "lscpu" {
        J = {
          args = ["--json"];
          description = "show CPU information as JSON";
        };
      })
      (mkAliasFamily "mountpoint" {
        q = {
          args = ["--quiet"];
          description = "check whether a path is a mount point through the exit status";
        };
      })
      (mkAliasFamily "column" {
        t = {
          args = ["--table"];
          description = "align input into table columns";
        };
        ts = {
          args = ["--table" "--separator"];
          description = "align input into a table using a caller-specified separator";
        };
      })
      (mkAliasFamily "dmesg" {
        Err = {
          args = ["--level=err,warn"];
          description = "show kernel errors and warnings";
        };
        H = {
          args = ["--human"];
          description = "show kernel messages with readable timestamps and paging";
        };
        w = {
          args = ["--follow"];
          description = "follow new kernel messages";
        };
      })
      (mkAliasFamily "findmnt" {
        J = {
          args = ["--json"];
          description = "show mounts as JSON";
        };
        T = {
          args = ["--types"];
          description = "show mounts of a caller-specified filesystem type";
        };
      })
      (mkAliasFamily "flock" {
        n = {
          args = ["--nonblock"];
          description = "fail immediately if the lock is already held";
        };
        w = {
          args = ["--wait"];
          description = "wait a caller-specified number of seconds for the lock";
        };
      })
      (mkAliasFamily "logger" {
        p = {
          args = ["--priority"];
          description = "write a message with a caller-specified priority";
        };
        S = {
          args = ["--stderr"];
          description = "write a message to the journal and also to standard error";
        };
        T = {
          args = ["-t"];
          description = "write a message to the journal with a caller-specified tag";
        };
      })
      (mkAliasFamily "lsblk" {
        a = {
          args = ["--all"];
          description = "list all block devices, including empty ones";
        };
        f = {
          args = ["--fs"];
          description = "list block devices with filesystem information";
        };
        J = {
          args = ["--json"];
          description = "list block devices as JSON";
        };
        p = {
          args = ["--paths"];
          description = "list block devices with full device paths";
        };
      })
      (mkAliasFamily "mount" {
        Bind = {
          args = ["--bind"];
          description = "bind-mount a directory at another location";
        };
        t = {
          args = ["--types"];
          description = "mount using a caller-specified filesystem type";
        };
      })
      (mkAliasFamily "umount" {
        l = {
          args = ["--lazy"];
          description = "detach a filesystem now and clean up when it is no longer busy";
        };
        R = {
          args = ["--recursive"];
          description = "unmount a filesystem and everything mounted beneath it";
        };
      })
    ];
  };

  iproute2 = mkSource {
    categories = ["networking" "scripting"];
    description = "ip, ss, bridge, and related networking tools";
    discover = true; #? ip, ss, bridge, ...
    exe = "ip";
    aliases = mergeDisjoint [
      (mkAliasFamily "ip" {
        "4" = {
          args = ["-4"];
          description = "limit output to IPv4";
        };
        "6" = {
          args = ["-6"];
          description = "limit output to IPv6";
        };
        BrAddr = {
          args = ["-brief" "address"];
          description = "show a compact table of interface addresses";
        };
        BrLink = {
          args = ["-brief" "link"];
          description = "show a compact table of interface link states";
        };
        Json = {
          args = ["-json"];
          description = "output JSON";
        };
        Neigh = {
          args = ["neighbour" "show"];
          description = "show the neighbour (ARP/NDP) table";
        };
        Route = {
          args = ["route" "show"];
          description = "show the routing table";
        };
      })
      (mkAliasFamily "ss" {
        Listen = {
          args = ["-tulpn"];
          description = "show listening TCP and UDP sockets with processes and numeric ports";
        };
        Summary = {
          args = ["--summary"];
          description = "show socket statistics";
        };
      })
    ];
  };
}
