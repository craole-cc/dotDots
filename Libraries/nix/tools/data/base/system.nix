{
  mkAliasFamily,
  mergeDisjoint,
  mkSource,
  ...
}: {
  coreutils = mkSource {
    categories = ["core" "scripting"];
    description = "core file, text, and shell utilities";
    discover = true;
    aliases = mergeDisjoint [
      (mkAliasFamily "base64" {
        d = {
          args = ["--decode"];
          description = "decode base64 input";
        };
        w0 = {
          args = ["--wrap=0"];
          description = "encode base64 without line wrapping";
        };
      })
      (mkAliasFamily "chmod" {
        "0600" = {
          args = ["0600"];
          description = "set permissions to 0600";
        };
        "0644" = {
          args = ["0644"];
          description = "set permissions to 0644";
        };
        "0755" = {
          args = ["0755"];
          description = "set permissions to 0755";
        };
        R = {
          args = ["-R"];
          description = "change permissions recursively";
        };
        Ref = {
          args = ["--reference"];
          description = "copy permissions from a reference file (caller supplies it)";
        };
        Ruw = {
          args = ["-R" "u+w"];
          description = "recursively add owner write permission";
        };
        x = {
          args = ["+x"];
          description = "make files executable";
        };
      })
      (mkAliasFamily "chown" {
        R = {
          args = ["-R"];
          description = "change ownership recursively";
        };
      })
      (mkAliasFamily "cp" {
        a = {
          args = ["-a" "--reflink=auto"];
          description = "copy recursively, preserving attributes and using reflinks when possible";
        };
        af = {
          args = ["-af" "--reflink=auto"];
          description = "force-copy recursively, preserving attributes and using reflinks when possible";
        };
      })
      (mkAliasFamily "cut" {
        d = {
          args = ["-d"];
          description = "cut using a caller-specified delimiter";
        };
        f = {
          args = ["-f"];
          description = "select caller-specified fields";
        };
      })
      (mkAliasFamily "date" {
        Epoch = {
          args = ["+%s"];
          description = "print the current Unix timestamp in seconds";
        };
        I = {
          args = ["-I"];
          description = "print the date in ISO format";
        };
        Is = {
          args = ["-Is"];
          description = "print the date and time in ISO format";
        };
        u = {
          args = ["-u"];
          description = "print the date and time in UTC";
        };
      })
      (mkAliasFamily "df" {
        h = {
          args = ["-h"];
          description = "show filesystem usage in human-readable sizes";
        };
      })
      (mkAliasFamily "du" {
        sh = {
          args = ["-sh"];
          description = "show the total human-readable size of each argument";
        };
      })
      (mkAliasFamily "echo" {
        n = {
          args = ["-n"];
          description = "print without a trailing newline";
        };
      })
      (mkAliasFamily "env" {
        i = {
          args = ["-i"];
          description = "run a command with an empty environment";
        };
        u = {
          args = ["-u"];
          description = "run a command with a caller-specified variable unset";
        };
      })
      (mkAliasFamily "head" {
        c = {
          args = ["-c"];
          description = "print the first caller-specified number of bytes";
        };
        n = {
          args = ["-n"];
          description = "print the first caller-specified number of lines";
        };
      })
      (mkAliasFamily "install" {
        D = {
          args = ["-D"];
          description = "install a file and create missing parent directories";
        };
        Dm = {
          args = ["-D" "-m"];
          description = "install with caller-specified permissions and create parent directories";
        };
        "0644" = {
          args = ["-D" "-m" "0644"];
          description = "install with 0644 permissions and create parent directories";
        };
        "0600" = {
          args = ["-D" "-m" "0600"];
          description = "install with 0600 permissions and create parent directories";
        };
        "0755" = {
          args = ["-D" "-m" "0755"];
          description = "install with 0755 permissions and create parent directories";
        };
        m = {
          args = ["-m"];
          description = "install with caller-specified permissions";
        };
      })
      (mkAliasFamily "ln" {
        sf = {
          args = ["-sf"];
          description = "create or replace a symbolic link";
        };
        sfn = {
          args = ["-sfn"];
          description = "create or replace a symbolic link, treating the destination as a file";
        };
        sr = {
          args = ["-sr"];
          description = "create a symbolic link with a path relative to the link location";
        };
      })
      (mkAliasFamily "mkdir" {
        p = {
          args = ["-p"];
          description = "create directories and any missing parents";
        };
        pv = {
          args = ["-pv"];
          description = "create directories and any missing parents, printing each one";
        };
      })
      (mkAliasFamily "mktemp" {
        d = {
          args = ["-d"];
          description = "create a temporary directory";
        };
      })
      (mkAliasFamily "mv" {
        t = {
          args = ["-T"];
          description = "move without treating the destination as a directory";
        };
        f = {
          args = ["-f"];
          description = "move files, replacing existing destinations without prompting";
        };
        n = {
          args = ["--no-clobber"];
          description = "move files without overwriting existing destinations";
        };
      })
      (mkAliasFamily "numfmt" {
        Iec = {
          args = ["--to=iec"];
          description = "convert byte counts to human-readable IEC sizes";
        };
      })
      (mkAliasFamily "paste" {
        d = {
          args = ["-d"];
          description = "merge lines using a caller-specified delimiter";
        };
      })
      (mkAliasFamily "readlink" {
        f = {
          args = ["-f"];
          description = "print the canonical absolute path of a file";
        };
        m = {
          args = ["-m"];
          description = "print the canonical path without requiring components to exist";
        };
      })
      (mkAliasFamily "realpath" {
        Rel = {
          args = ["--relative-to"];
          description = "print a path relative to a caller-specified base";
        };
      })
      (mkAliasFamily "rm" {
        f = {
          args = ["-f"];
          description = "remove files without prompting or failing on missing ones";
        };
        r = {
          args = ["-r"];
          description = "remove directories recursively";
        };
        rf = {
          args = ["-rf"];
          description = "remove files and directories recursively without prompting";
        };
      })
      (mkAliasFamily "rmdir" {
        p = {
          args = ["-p"];
          description = "remove a directory and its empty parents";
        };
      })
      (mkAliasFamily "seq" {
        w = {
          args = ["-w"];
          description = "print a number sequence padded with leading zeros";
        };
      })
      (mkAliasFamily "sha256sum" {
        c = {
          args = ["--check"];
          description = "verify SHA-256 checksums from a file";
        };
      })
      (mkAliasFamily "sort" {
        n = {
          args = ["-n"];
          description = "sort lines by numeric value";
        };
        nr = {
          args = ["-nr"];
          description = "sort lines by numeric value, largest first";
        };
        k = {
          args = ["-k"];
          description = "sort by a caller-specified key";
        };
        r = {
          args = ["-r"];
          description = "sort lines in reverse order";
        };
        u = {
          args = ["-u"];
          description = "sort lines and remove duplicates";
        };
        V = {
          args = ["-V"];
          description = "sort lines by version number";
        };
      })
      (mkAliasFamily "stat" {
        c = {
          args = ["-c"];
          description = "print file status using a caller-specified format";
        };
      })
      (mkAliasFamily "tail" {
        c = {
          args = ["-c"];
          description = "print the caller-specified number of trailing bytes";
        };
        F = {
          args = ["-F"];
          description = "follow a file by name and continue after log rotation";
        };
        n = {
          args = ["-n"];
          description = "print the caller-specified number of trailing lines";
        };
      })
      (mkAliasFamily "tee" {
        a = {
          args = ["-a"];
          description = "append standard input to files and pass it to standard output";
        };
      })
      (mkAliasFamily "touch" {
        d = {
          args = ["-d"];
          description = "set file times to a caller-specified date";
        };
        r = {
          args = ["-r"];
          description = "copy file times from a reference file";
        };
      })
      (mkAliasFamily "tr" {
        d = {
          args = ["-d"];
          description = "delete caller-specified characters";
        };
        s = {
          args = ["-s"];
          description = "squeeze repeated characters into one";
        };
      })
      (mkAliasFamily "truncate" {
        S = {
          args = ["-s"];
          description = "set a file to a caller-specified size";
        };
      })
      (mkAliasFamily "uniq" {
        c = {
          args = ["-c"];
          description = "count adjacent duplicate lines";
        };
        d = {
          args = ["-d"];
          description = "print only duplicated lines";
        };
      })
      (mkAliasFamily "wc" {
        c = {
          args = ["-c"];
          description = "count bytes";
        };
        l = {
          args = ["-l"];
          description = "count lines";
        };
        w = {
          args = ["-w"];
          description = "count words";
        };
      })
    ];
  };

  gnupatch = mkSource {
    categories = ["core" "scripting"];
    description = "apply diff patches";
    exe = "patch";
    aliases = mkAliasFamily "patch" {
      d = {
        args = ["-d"];
        description = "apply a patch from a caller-specified directory";
      };
      Dry = {
        args = ["--dry-run"];
        description = "test whether a patch applies without changing files";
      };
      i = {
        args = ["-i"];
        description = "read the patch from a caller-specified file";
      };
      p0 = {
        args = ["-p0"];
        description = "apply a patch without stripping path components";
      };
      p1 = {
        args = ["-p1"];
        description = "apply a patch stripping one leading path component";
      };
      R = {
        args = ["-R"];
        description = "reverse a previously applied patch";
      };
    };
  };

  moreutils = mkSource {
    categories = ["core" "scripting"];
    description = "additional Unix tools, including sponge and parallel";
    discover = true;
    aliases = mergeDisjoint [
      (mkAliasFamily "ifne" {
        n = {
          args = ["-n"];
          description = "run the command only when standard input is empty";
        };
      })
      (mkAliasFamily "parallel" {
        j = {
          args = ["-j"];
          description = "run a caller-specified number of jobs at once";
        };
      })
      (mkAliasFamily "sponge" {
        a = {
          args = ["-a"];
          description = "append buffered standard input to a file";
        };
      })
      (mkAliasFamily "chronic" {
        E = {
          args = ["-e"];
          description = "treat any standard error output as a failure and show the output";
        };
        v = {
          args = ["-v"];
          description = "run quietly unless the command fails, with verbose failure output";
        };
      })
      (mkAliasFamily "ts" {
        Elapsed = {
          args = ["-s"];
          description = "prefix each line with the time elapsed since start";
        };
        Incremental = {
          args = ["-i"];
          description = "prefix each line with the time since the previous line";
        };
      })
    ];
  };

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
}
