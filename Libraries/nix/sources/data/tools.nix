{_, ...}: let
  inherit (_.attrsets.access) attrNames;
  inherit (_.attrsets.aggregation) intersectAttrs;
  inherit (_.content.emptiness) isNotEmpty;
  inherit (_.filesystem.access) readFile;
  inherit (_.attrsets.construction) optionalAttrs nameValuePair;
  inherit (_.attrsets.transformation) mapAttrs' mapAttrsToList;
  inherit (_.lists.aggregation) concatMap foldl';
  inherit (_.lists.predicates) all elem;
  inherit (_.lists.transformation) filter;
  inherit (_.strings.construction) concat;
  inherit (_.strings.transformation) replaceStrings;

  mkAlias = command: {
    args ? [],
    description ? null,
    after ? [],
  }:
    {
      cmd = [command] ++ args;
      inherit description;
    }
    // optionalAttrs (isNotEmpty after) {inherit after;};

  #? Layers carry args, an optional trailing list (always placed last), and a description.
  mkLayeredAlias = command: baseLayers: layers: let
    allLayers = baseLayers ++ layers;
  in
    mkAlias command {
      args =
        concatMap (layer: layer.args or []) allLayers
        ++ concatMap (layer: layer.trailing or []) allLayers;
      description = concat ", " (
        filter (text: text != null)
        (map (layer: layer.description or null) allLayers)
      );
    };
  #? mkAliasFamily "chmod" {R = {...}; x = {...};} yields chmodR and chmodx.

  mkAliasFamily = command: variants: let
    prefix = variants.aliasPrefix or command;
    specs = removeAttrs variants ["aliasPrefix"];
  in
    mapAttrs' (
      suffix: spec:
        nameValuePair (prefix + suffix) (mkAlias command spec)
    )
    specs;

  #? Throws on a repeated alias name instead of silently keeping the last one.
  mergeDisjoint = attrsets:
    foldl' (merged: next: let
      clashing = attrNames (intersectAttrs merged next);
    in
      if clashing == []
      then merged // next
      else throw "duplicate aliases: ${concat ", " clashing}") {}
    attrsets;

  mkSource = {
    categories,
    description,
    ...
  } @ source:
    assert all (category:
      elem category [
        "archives"
        "audio"
        "communication"
        "core"
        "desktop-cli"
        "desktop-ui"
        "editors"
        "files"
        "formatters"
        "media"
        "networking"
        "scripting"
        "shells"
        "system"
        "text"
        "version-control"
        "video"
      ])
    categories;
      source // {inherit categories description;};
in {
  alejandra = mkSource {
    categories = ["formatters" "scripting"];
    description = "opinionated Nix formatter";
    aliases = mkAliasFamily "alejandra" {
      aliasPrefix = "alj";
      Check = {
        args = ["--check"];
        description = "check formatting without changing files";
      };
      Quiet = {
        args = ["--quiet"];
        description = "format files without printing progress output";
      };
      Here = {
        args = ["."];
        description = "format every Nix file under the current directory";
      };
    };
  };

  bash = mkSource {
    categories = ["shells" "scripting"];
    description = "Bourne-again shell";
    aliases = mkAliasFamily "bash" {
      c = {
        args = ["-c"];
        description = "run a command string";
      };
      n = {
        args = ["-n"];
        description = "check a script's syntax without running it";
      };
      x = {
        args = ["-x"];
        description = "run a script while tracing each command";
      };
      Strict = {
        args = ["-euo" "pipefail"];
        description = "run a script with strict error handling";
      };
    };
  };

  bat = mkSource {
    categories = ["files" "scripting"];
    description = "cat with syntax highlighting";
    aliases = mkAliasFamily "bat" {
      d = {
        args = ["--diff"];
        description = "show only lines changed relative to the git index";
      };
      l = {
        args = ["--language"];
        description = "force a syntax language (caller supplies it)";
      };
      n = {
        args = ["--number"];
        description = "show line numbers";
      };
      p = {
        args = ["--plain"];
        description = "print without decorations or syntax highlighting";
      };
      pp = {
        args = ["-pp"];
        description = "print plain without paging";
      };
      r = {
        args = ["--line-range"];
        description = "print only a caller-specified line range";
      };
    };
  };

  biome = mkSource {
    categories = ["formatters" "scripting"];
    description = "fast formatter and linter for JS, TS, JSON, and CSS";
    aliases = mkAliasFamily "biome" {
      Check = {
        args = ["check"];
        description = "run the formatter, linter, and import sorting checks";
      };
      Fix = {
        args = ["check" "--write"];
        description = "run all checks and apply safe fixes";
      };
      CI = {
        args = ["ci"];
        description = "run read-only checks suited to CI";
      };
      Format = {
        args = ["format" "--write"];
        description = "format files in place";
      };
      Lint = {
        args = ["lint"];
        description = "lint files without changing them";
      };
    };
  };

  cmus = mkSource {
    categories = ["media" "audio"];
    description = "console-based music player";
    aliases = mergeDisjoint [
      (mkAliasFamily "cmus-remote" {
        aliasPrefix = "cmus";
        Next = {
          args = ["-n"];
          description = "skip to the next track";
        };
        Pause = {
          args = ["-u"];
          description = "toggle playback pause";
        };
        Play = {
          args = ["-p"];
          description = "start or resume playback";
        };
        Previous = {
          args = ["-r"];
          description = "return to the previous track";
        };
        Quit = {
          args = ["-q"];
          description = "quit the running cmus instance";
        };
        Repeat = {
          args = ["-R"];
          description = "toggle repeat mode";
        };
        Shuffle = {
          args = ["-S"];
          description = "toggle shuffle mode";
        };
        Status = {
          args = ["-Q"];
          description = "print the current player status and track metadata";
        };
        Stop = {
          args = ["-s"];
          description = "stop playback";
        };
      })
      (mkAliasFamily "cmus" {
        Help = {
          args = ["-h"];
          description = "show command-line help";
        };
        Version = {
          args = ["-v"];
          description = "show the installed version";
        };
      })
    ];
  };

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

  curl = mkSource {
    categories = ["networking" "scripting"];
    description = "transfer data with URLs";
    aliases = mkAliasFamily "curl" {
      fsSL = {
        args = ["-fsSL"];
        description = "fetch quietly, follow redirects, and fail on HTTP errors";
      };
      I = {
        args = ["--head"];
        description = "fetch response headers only";
      };
      Json = {
        args = ["-fsSL" "-H" "Accept: application/json"];
        description = "fetch quietly while requesting a JSON response";
      };
      L = {
        args = ["--location"];
        description = "follow redirects";
      };
      O = {
        args = ["--remote-name"];
        description = "save the download using its remote file name";
      };
      Output = {
        args = ["--output"];
        description = "save the download to a caller-specified path";
      };
      Retry = {
        args = ["-fsSL" "--retry" "3" "--retry-delay" "2"];
        description = "fetch quietly and retry transient failures up to three times";
      };
    };
  };

  dash = mkSource {
    categories = ["shells" "scripting"];
    description = "lightweight POSIX sh for `write.posix` shebangs";
    aliases = mkAliasFamily "dash" {
      c = {
        args = ["-c"];
        description = "run a command string with POSIX sh";
      };
      n = {
        args = ["-n"];
        description = "check a script's syntax without running it";
      };
      x = {
        args = ["-x"];
        description = "run a script while tracing each command";
      };
    };
  };

  dbus = mkSource {
    categories = ["desktop-cli" "scripting"];
    description = "D-Bus command-line tools, including dbus-send and dbus-monitor";
    discover = true; #? dbus-send, dbus-monitor, ...
    exe = "dbus-send";
    aliases = mergeDisjoint [
      (mkAliasFamily "dbus-monitor" {
        aliasPrefix = "dbusMonitor";
        Session = {
          args = ["--session"];
          description = "watch messages on the session bus";
        };
        System = {
          args = ["--system"];
          description = "watch messages on the system bus";
        };
      })
      (mkAliasFamily "dbus-send" {
        aliasPrefix = "dbus";
        SessionCall = {
          args = ["--session" "--print-reply" "--type=method_call" "--dest"];
          description = "call a session bus method and print the reply (caller supplies destination, path, and method)";
        };
        SystemCall = {
          args = ["--system" "--print-reply" "--type=method_call" "--dest"];
          description = "call a system bus method and print the reply (caller supplies destination, path, and method)";
        };
      })
    ];
  };

  diffutils = mkSource {
    categories = ["core" "scripting"];
    description = "cmp, diff, diff3, and sdiff";
    discover = true; #? cmp, diff, diff3, sdiff
    exe = "cmp";
    aliases = mergeDisjoint [
      (mkAliasFamily "cmp" {
        l = {
          args = ["-l"];
          description = "list every differing byte";
        };
        s = {
          args = ["-s"];
          description = "compare files without printing differences";
        };
      })
      (mkAliasFamily "diff" {
        q = {
          args = ["-q"];
          description = "report only whether files differ";
        };
        u = {
          args = ["-u"];
          description = "show differences in unified format";
        };
        ur = {
          args = ["-ur"];
          description = "show recursive differences in unified format";
        };
        urN = {
          args = ["-urN"];
          description = "show recursive unified differences, treating absent files as empty";
        };
        y = {
          args = ["--side-by-side"];
          description = "show differences side by side";
        };
      })
    ];
  };

  dms-shell = mkSource {
    categories = ["desktop-ui"];
    description = "Dank Material Shell";
    input = "dank-material-shell";
    aliases = mkAliasFamily "dms" {
      Call = {args = ["ipc" "call"];};
      Set = {args = ["ipc" "call" "settings" "set"];};
    };
    transform = {
      package,
      source,
      builders,
      ...
    }: let
      patchedSource = builders.applyPatches {
        name = "dms-patched-source";
        src = source;
        patches = [
          ../patches/dms/theme-control.patch
          ../patches/dms/catppuccin-matugen.patch
          ../patches/dms/notification-scratchpad-activation.patch
        ];
      };
    in
      package.overrideAttrs (previous: {
        src = "${patchedSource}/core";
        postInstall =
          replaceStrings
          [source]
          ["${patchedSource}"]
          previous.postInstall;
        passthru =
          (previous.passthru or {})
          // {shellSource = "${patchedSource}/quickshell";};
      });
  };

  glow = mkSource {
    categories = ["text" "scripting"];
    description = "terminal Markdown reader";
    aliases = let
      cfg = {
        dark = {
          args = ["--style" "dark"];
          description = "for a dark terminal background";
        };
        light = {
          args = ["--style" "light"];
          description = "for a light terminal background";
        };
        page = {
          args = ["--pager"];
          description = "in a pager";
        };
      };
      mkGlow = mkLayeredAlias "glow" [{description = "render Markdown";}];
      mkStyleAlias = name: style: {
        ${name} = mkGlow [style];
        "${name}p" = mkGlow [style cfg.page];
      };
    in
      {glowp = mkGlow [cfg.page];}
      // (mkStyleAlias "glowDark" cfg.dark)
      // (mkStyleAlias "glowLight" cfg.light)
      // (mkStyleAlias "mdD" cfg.dark)
      // (mkStyleAlias "mdL" cfg.light);
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

  khal = mkSource {
    categories = ["communication"];
    description = "terminal calendar";
    # The locked Sphinx hook reads a scalar even with structured attributes.
    transform = package:
      package.overridePythonAttrs (_previous: {
        sphinxBuilders = "html man";
      });
  };

  rust-script = mkSource {
    categories = ["scripting"];
    description = "run Rust files and expressions as scripts";
    target = "rust-script";
    exe = "rust-script";
  };

  vdirsyncer = mkSource {
    categories = ["communication"];
    description = "CalDAV calendar synchronisation";
    target = "vdirsyncer";
    exe = "vdirsyncer";
  };

  thunderbird = mkSource {
    categories = ["communication"];
    description = "email and calendar client";
    target = "thunderbird";
    exe = "thunderbird";
  };

  python3 = mkSource {
    categories = ["communication"];
    description = "Python runtime";
    target = "python3";
    exe = "python3";
  };

  dux-calendar = mkSource {
    categories = ["desktop-ui"];
    description = "Dux Calendar";
    target = "dankcalendar";
  };

  dprint = mkSource {
    categories = ["formatters" "scripting"];
    description = "pluggable multi-language code formatter";
    aliases = mkAliasFamily "dprint" {
      Check = {
        args = ["check"];
        description = "check formatting without changing files";
      };
      Fmt = {
        args = ["fmt"];
        description = "format files in place";
      };
      Init = {
        args = ["init"];
        description = "create a dprint configuration file";
      };
    };
  };

  dust = mkSource {
    categories = ["files" "scripting"];
    description = "intuitive du (disk usage)";
    aliases = mkAliasFamily "dust" {
      d = {
        args = ["-d"];
        description = "limit the directory depth shown";
      };
      Dirs = {
        args = ["-D"];
        description = "show only directories";
      };
      n = {
        args = ["-n"];
        description = "show a caller-specified number of entries";
      };
      r = {
        args = ["-r"];
        description = "show the largest entries at the bottom";
      };
    };
  };

  eza = mkSource {
    categories = ["files" "scripting"];
    description = "modern ls replacement";
    aliases = let
      cfg = {
        default = {
          args = ["--icons=auto" "--color=auto"];
          description = "with sane defaults";
        };
        plain = {
          args = ["--icons=never" "--color=never" "--oneline"];
          description = "with plain output, one entry per line";
        };
        hidden = {
          args = ["--almost-all"];
          description = "with hidden files";
        };
        info = {
          args = ["--long" "--git"];
          description = "with metadata columns";
        };
        tree = {
          args = ["--tree"];
          description = "with tree output";
        };
        recursive = {
          args = ["--recurse"];
          description = "with recursive output";
        };
        dirs = {
          args = ["--only-dirs"];
          description = "listing only directories";
        };
        #? Must stay last so the caller's next argument becomes its value.
        level = {
          trailing = ["--level"];
          description = "limited to a required depth";
        };
      };

      mkEza = mkLayeredAlias "eza" [cfg.default];
      # #> Builds one alias from cfg.default plus any number of cfg layers.
      # #? Args are concatenated in order (later flags win in eza);
      # #? trailing args from every layer are appended last;
      # #? descriptions are joined with ", ".
      # mkLayered = layers:
      #   mkAlias "eza" {
      #     args =
      #       concatMap (layer: layer.args or []) ([cfg.default] ++ layers)
      #       ++ concatMap (layer: layer.trailing or []) layers;
      #     description = concat ", " (
      #       if layers == []
      #       then [cfg.default.description]
      #       else
      #         filter (text: text != null)
      #         (map (layer: layer.description or null) layers)
      #     );
      #   };

      #? name / namea / namep / namepa / nameap: the view with metadata, hidden files,
      #? plain output, or plain output including hidden files.
      mkViewAlias = name: view: let
        mkPlain = extra: mkEza ([view cfg.plain] ++ extra);
      in {
        ${name} = mkEza [view cfg.info];
        "${name}a" = mkEza [view cfg.hidden];
        "${name}p" = mkPlain [];
        "${name}pa" = mkPlain [cfg.hidden];
        "${name}ap" = mkPlain [cfg.hidden];
      };

      #? Like mkViewAlias, but the caller must supply a depth (e.g. `et 2`).
      mkRecursiveAlias = name: mode:
        mkViewAlias name {
          inherit (mode) args;
          inherit (cfg.level) trailing;
          description = "${mode.description}, ${cfg.level.description}";
        };

      mkSortAlias = name: by:
        mkViewAlias name {
          args = ["--sort=${by}"];
          description = "list sorted by ${by}";
        };
    in
      mergeDisjoint (
        [{ez = mkEza [];}]
        ++ [
          (mkViewAlias "ee" {})
          (mkViewAlias "ed" cfg.dirs)
          (mkViewAlias "ezal" {})
          (mkViewAlias "ezad" cfg.dirs)
          (mkViewAlias "ezat" cfg.tree)
          (mkViewAlias "ezar" cfg.recursive)
          (mkRecursiveAlias "et" cfg.tree)
          (mkRecursiveAlias "er" cfg.recursive)
        ]
        ++ mapAttrsToList mkSortAlias {
          ezan = "name";
          ezaN = "Name";
          ezanDot = ".name";
          ezaNDot = ".Name";
          ezae = "ext";
          ezam = "modified";
          ezac = "created";
          ezaa = "accessed";
          ezaChanged = "changed";
          ezas = "size";
          ezai = "inode";
          ezaType = "type";
          ezaNone = "none";
        }
      );
  };

  fd = mkSource {
    categories = ["files" "scripting"];
    description = "simple, fast find alternative";
    aliases = mkAliasFamily "fd" {
      "0" = {
        args = ["--print0"];
        description = "separate results with NUL bytes";
      };
      d = {
        args = ["--type" "d"];
        description = "find directories only";
      };
      e = {
        args = ["--extension"];
        description = "find files with a caller-specified extension";
      };
      ExecBatch = {
        args = ["--exec-batch"];
        description = "run one command with all results as arguments";
      };
      f = {
        args = ["--type" "f"];
        description = "find regular files only";
      };
      g = {
        args = ["--glob"];
        description = "match with a glob pattern instead of a regex";
      };
      h = {
        args = ["--hidden" "--no-ignore"];
        description = "find files including hidden and ignored paths";
      };
      md = {
        args = ["--max-depth"];
        description = "limit the search depth";
      };
      x = {
        args = ["--exec"];
        description = "run a command once for each result";
      };
    };
  };

  file = mkSource {
    categories = ["core" "scripting"];
    description = "determine file type";
    aliases = mkAliasFamily "file" {
      b = {
        args = ["--brief"];
        description = "print the file type without the file name";
      };
      L = {
        args = ["--dereference"];
        description = "follow symbolic links";
      };
      Mime = {
        args = ["--mime-type"];
        description = "print the MIME type";
      };
    };
  };

  findutils = mkSource {
    categories = ["core" "scripting"];
    description = "xargs (find is covered by fd)";
    discover = true;
    aliases = mergeDisjoint [
      {
        find0 = (mkAlias "find") {
          args = ["-print0"];
          description = "find paths and separate results with NUL bytes";
        };
      }
      (mkAliasFamily "xargs" {
        "0" = {
          args = ["-0"];
          description = "read NUL-separated arguments from standard input";
        };
        "0r" = {
          args = ["-0" "-r"];
          description = "read NUL-separated arguments and skip the command when there are none";
        };
        n = {
          args = ["-n"];
          description = "pass a caller-specified number of arguments per command";
        };
        P = {
          args = ["-P"];
          description = "run a caller-specified number of commands in parallel";
        };
        r = {
          args = ["-r"];
          description = "run the command only when standard input contains arguments";
        };
        I = {
          args = ["-I" "{}"];
          description = "replace each {} in the command with an input line";
        };
      })
    ];
  };

  fzf = mkSource {
    categories = ["files" "scripting"];
    description = "command-line fuzzy finder";
    aliases = mkAliasFamily "fzf" {
      "0" = {
        args = ["--read0" "--print0"];
        description = "read and write NUL-separated items";
      };
      "1" = {
        args = ["--select-1" "--exit-0"];
        description = "auto-select a single match and exit when nothing matches";
      };
      e = {
        args = ["--exact"];
        description = "use exact matching instead of fuzzy matching";
      };
      h = {
        args = ["--height" "40%"];
        description = "run inline using 40% of the terminal height";
      };
      m = {
        args = ["--multi"];
        description = "allow selecting multiple items";
      };
      p = {
        args = ["--preview"];
        description = "show a preview command for the highlighted item (caller supplies it)";
      };
      q = {
        args = ["--query"];
        description = "start with a caller-specified query";
      };
      r = {
        args = ["--reverse"];
        description = "show the prompt at the top with results below";
      };
    };
  };

  gawk = mkSource {
    categories = ["core" "scripting"];
    description = "GNU awk";
    discover = true;
    aliases = mergeDisjoint [
      {
        awkInplace = (mkAlias "gawk") {
          args = ["-i" "inplace"];
          description = "edit files in place";
        };
      }
      (mkAliasFamily "awk" {
        F = {
          args = ["-F"];
          description = "set the input field separator";
        };
        File = {
          args = ["-f"];
          description = "run an awk program from a file";
        };
        v = {
          args = ["-v"];
          description = "assign a variable before running the program";
        };
      })
    ];
  };

  gh = mkSource {
    categories = ["shells" "scripting"];
    description = "GitHub CLI";
    aliases = mkAliasFamily "gh" {
      Api = {
        args = ["api"];
        description = "call a GitHub API endpoint";
      };
      AuthStatus = {
        args = ["auth" "status"];
        description = "show authentication status";
      };
      IssueCreate = {
        args = ["issue" "create"];
        description = "create an issue";
      };
      IssueList = {
        args = ["issue" "list"];
        description = "list issues";
      };
      PrCheckout = {
        args = ["pr" "checkout"];
        description = "check out a pull request locally";
      };
      PrCreate = {
        args = ["pr" "create"];
        description = "create a pull request";
      };
      PrList = {
        args = ["pr" "list"];
        description = "list pull requests";
      };
      PrStatus = {
        args = ["pr" "status"];
        description = "show the status of relevant pull requests";
      };
      PrView = {
        args = ["pr" "view"];
        description = "view a pull request";
      };
      RepoClone = {
        args = ["repo" "clone"];
        description = "clone a repository";
      };
      RepoView = {
        args = ["repo" "view"];
        description = "view a repository summary";
      };
      RepoViewWeb = {
        args = ["repo" "view" "--web"];
        description = "open a repository in the browser";
      };
      RunList = {
        args = ["run" "list"];
        description = "list recent workflow runs";
      };
      RunWatch = {
        args = ["run" "watch"];
        description = "watch a workflow run until it finishes";
      };
    };
  };

  git = let
    mkHelper = name: description:
      mkAlias "git" {
        args = [
          "-c"
          "alias.project-${name}=!helper() {\n${readFile (../../../posix/project/git + "/${name}")}\n}; helper"
          "project-${name}"
        ];
        inherit description;
      };
  in
    mkSource {
      categories = ["shells" "scripting"];
      description = "distributed version control";
      aliases = mergeDisjoint [
        (mkAliasFamily "git" {
          AddAll = {
            args = ["add" "--all"];
            description = "stage all changes, including deletions and new files";
          };
          BranchCurrent = {
            args = ["branch" "--show-current"];
            description = "print the current branch name";
          };
          CfgFile = {
            args = ["config" "--file"];
            description = "read or write configuration in a caller-specified file";
          };
          Check = {
            args = [
              "-c"
              "alias.check=!git fetch origin; git status --short; git log --oneline -5; git log --oneline @{u}.."
              "check"
            ];
            description = "fetch origin and show status, recent commits and unpushed commits";
          };
          CloneShallow = {
            args = ["clone" "--depth" "1"];
            description = "clone only the latest commit";
          };
          Commit = {
            args = ["commit" "--message"];
            description = "commit with a caller-specified message";
          };
          CommitAmend = {
            args = ["commit" "--amend"];
            description = "amend the previous commit";
          };
          CommitAmendNoEdit = {
            args = ["commit" "--amend" "--no-edit"];
            description = "amend the previous commit and keep its message";
          };
          DiffStaged = {
            args = ["diff" "--staged"];
            description = "show staged changes";
          };
          FetchPrune = {
            args = ["fetch" "--all" "--prune"];
            description = "fetch every remote and prune deleted branches";
          };
          LogGraph = {
            args = ["log" "--oneline" "--graph" "--decorate"];
            description = "show a compact commit graph";
          };
          PullRebase = {
            args = ["pull" "--rebase"];
            description = "pull and rebase local commits on top";
          };
          PushForce = {
            args = ["push" "--force-with-lease"];
            description = "force-push only if the remote has not changed unexpectedly";
          };
          RestoreStaged = {
            args = ["restore" "--staged"];
            description = "unstage files while keeping their changes";
          };
          SwitchCreate = {
            args = ["switch" "--create"];
            description = "create and switch to a new branch";
          };
          TopLevel = {
            args = ["rev-parse" "--show-toplevel"];
            description = "print the repository root";
          };
        })
        {
          gitFetch = mkHelper "gitFetch" "fetch remotes in the current repository";
          gitStatus = mkHelper "gitStatus" "fetch remotes and show status and recent commits in the current repository";
        }
      ];
    };

  git-filter-repo = mkSource {
    categories = ["version-control" "scripting"];
    description = "rewrite Git repository history safely and efficiently";
    exe = "git-filter-repo";
    aliases = mergeDisjoint [
      (mkAliasFamily "git-filter-repo" {
        aliasPrefix = "gitFilter";
        Analyze = {
          args = ["--analyze"];
          description = "analyse repository history without rewriting it";
        };
        Path = {
          args = ["--path"];
          description = "keep a caller-specified path in history";
        };
        RemovePath = {
          args = ["--invert-paths" "--path"];
          description = "remove a caller-specified path from history";
        };
        PathGlob = {
          args = ["--path-glob"];
          description = "keep paths matching a caller-specified glob";
        };
        PathRename = {
          args = ["--path-rename"];
          description = "rename paths using a caller-specified old:new mapping";
        };
        PathsFile = {
          args = ["--paths-from-file"];
          description = "read path filters and renames from a caller-specified file";
        };
        Subdirectory = {
          args = ["--subdirectory-filter"];
          description = "extract a caller-specified subdirectory as the repository root";
        };
        ToSubdirectory = {
          args = ["--to-subdirectory-filter"];
          description = "move repository history under a caller-specified subdirectory";
        };
        ReplaceText = {
          args = ["--replace-text"];
          description = "replace file contents using a caller-specified expressions file";
        };
        StripLargeBlobs = {
          args = ["--strip-blobs-bigger-than"];
          description = "remove blobs larger than a caller-specified size";
        };
        Mailmap = {
          args = ["--mailmap"];
          description = "rewrite author identities using a caller-specified mailmap";
        };
        TagRename = {
          args = ["--tag-rename"];
          description = "rename tag prefixes using a caller-specified old:new mapping";
        };
      })
    ];
  };

  gitui = mkSource {
    categories = ["version-control"];
    description = "terminal user interface for Git";
    aliases = mkAliasFamily "gitui" {
      Directory = {
        args = ["--directory"];
        description = "open a caller-specified Git directory";
      };
      File = {
        args = ["--file"];
        description = "select a caller-specified file in the file tab";
      };
      KeyBindings = {
        args = ["--key-bindings"];
        description = "use a caller-specified keybindings file";
      };
      LogFile = {
        args = ["--logfile"];
        description = "write logs to a caller-specified file";
      };
      Theme = {
        args = ["--theme"];
        description = "load a caller-specified theme from the config directory";
      };
      Watcher = {
        args = ["--watcher"];
        description = "update using file system notifications";
      };
      Workdir = {
        args = ["--workdir"];
        description = "use a caller-specified working directory";
      };
    };
  };

  glib = mkSource {
    categories = ["desktop-cli" "scripting"];
    description = "gdbus, gio, and gsettings";
    discover = true; #? gdbus, gio, gsettings, ...
    exe = "gsettings";
    aliases = mergeDisjoint [
      (mkAliasFamily "gdbus" {
        aliasPrefix = "g";
        Call = {
          args = ["call"];
          description = "call a method on a D-Bus object";
        };
        Introspect = {
          args = ["introspect" "--session" "--dest"];
          description = "introspect a session bus service (caller supplies destination and path)";
        };
        Monitor = {
          args = ["monitor" "--session" "--dest"];
          description = "watch signals from a session bus service";
        };
      })
      (mkAliasFamily "gsettings" {
        aliasPrefix = "g";
        Get = {
          args = ["get"];
          description = "read a caller-specified GSettings key";
        };
        GetDI = {
          args = ["get" "org.gnome.desktop.interface"];
          description = "read a GNOME desktop interface setting";
        };
        ListAll = {
          args = ["list-recursively"];
          description = "list every key and value in a schema";
        };
        Reset = {
          args = ["reset"];
          description = "reset a GSettings key to its default";
        };
        Set = {
          args = ["set"];
          description = "set a caller-specified GSettings key";
        };
        SetDI = {
          args = ["set" "org.gnome.desktop.interface"];
          description = "set a GNOME desktop interface setting";
        };
      })
      (mkAliasFamily "gio" {
        Info = {
          args = ["info"];
          description = "show file information and attributes";
        };
        Open = {
          args = ["open"];
          description = "open a file or URI with its default application";
        };
        Trash = {
          args = ["trash"];
          description = "move files to the trash";
        };
      })
    ];
  };

  gnugrep = mkSource {
    categories = ["core" "scripting"];
    description = "GNU grep";
    discover = true;
    aliases = mkAliasFamily "grep" {
      c = {
        args = ["-c"];
        description = "count matching lines";
      };
      E = {
        args = ["-E"];
        description = "use extended regular expressions";
      };
      F = {
        args = ["-F"];
        description = "match fixed strings instead of regular expressions";
      };
      Fxq = {
        args = ["-Fxq"];
        description = "quietly search for an exact fixed-string line";
      };
      i = {
        args = ["-i"];
        description = "search case-insensitively";
      };
      l = {
        args = ["-l"];
        description = "print only the names of files with matches";
      };
      n = {
        args = ["-n"];
        description = "show line numbers for matches";
      };
      o = {
        args = ["-o"];
        description = "print only the matching part of each line";
      };
      P = {
        args = ["-P"];
        description = "use Perl-compatible regular expressions";
      };
      q = {
        args = ["-q"];
        description = "search quietly and report success through the exit status";
      };
      r = {
        args = ["-r"];
        description = "search files recursively";
      };
      ri = {
        args = ["-ri"];
        description = "search files recursively, ignoring case";
      };
      v = {
        args = ["-v"];
        description = "select non-matching lines";
      };
      w = {
        args = ["-w"];
        description = "match whole words only";
      };
    };
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

  gnused = mkSource {
    categories = ["core" "scripting"];
    description = "GNU sed";
    discover = true;
    aliases = mkAliasFamily "sed" {
      E = {
        args = ["-E"];
        description = "use extended regular expressions";
      };
      i = {
        args = ["-i"];
        description = "edit files in place";
      };
      iBak = {
        args = ["-i.bak"];
        description = "edit files in place and keep .bak backups";
      };
      iE = {
        args = ["-i" "-E"];
        description = "edit files in place using extended regular expressions";
      };
      n = {
        args = ["-n"];
        description = "print only explicitly selected lines";
      };
      nE = {
        args = ["-nE"];
        description = "print only selected lines using extended regular expressions";
      };
      z = {
        args = ["-z"];
        description = "treat NUL-separated records as lines";
      };
    };
  };

  gum = mkSource {
    categories = ["shells" "scripting"];
    description = "glamorous shell script helpers";
    aliases = mkAliasFamily "gum" {
      Choose = {
        args = ["choose"];
        description = "pick one option from a list";
      };
      ChooseMulti = {
        args = ["choose" "--no-limit"];
        description = "pick any number of options from a list";
      };
      Confirm = {
        args = ["confirm"];
        description = "ask a yes/no question and report the answer through the exit status";
      };
      File = {
        args = ["file"];
        description = "pick a file from a directory";
      };
      Filter = {
        args = ["filter"];
        description = "fuzzy-filter lines from standard input";
      };
      Input = {
        args = ["input"];
        description = "prompt for a single line of text";
      };
      Log = {
        args = ["log"];
        description = "print a structured log message";
      };
      Pager = {
        args = ["pager"];
        description = "scroll through text in a pager";
      };
      Spin = {
        args = ["spin" "--title"];
        description = "show a spinner while a command runs (caller supplies the title, then -- and the command)";
      };
      Style = {
        args = ["style"];
        description = "apply colors, borders, and spacing to text";
      };
      Write = {
        args = ["write"];
        description = "prompt for multi-line text";
      };
    };
  };

  hyprpaper = mkSource {
    categories = ["desktop-ui"];
    description = "wallpaper daemon for Hyprland";
    aliases = mkAliasFamily "hyprpaper" {
      Config = {
        args = ["--config"];
        description = "start with a caller-specified configuration file";
      };
    };
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

  kew = mkSource {
    categories = ["media" "audio"];
    description = "terminal music player and library browser";
    aliases = mkAliasFamily "kew" {
      Albums = {
        args = ["albums"];
        description = "play albums from the music library in random order";
      };
      All = {
        args = ["all"];
        description = "play all songs in the music library shuffled";
      };
      Dir = {
        args = ["dir"];
        description = "find and play a directory by name";
      };
      Exact = {
        args = ["--exact"];
        description = "match a song, album, or artist name exactly";
      };
      Favorites = {
        args = ["."];
        description = "play the favourites playlist";
      };
      Help = {
        args = ["--help"];
        description = "show command-line help";
      };
      List = {
        args = ["list"];
        description = "play a named playlist";
      };
      NoCover = {
        args = ["--nocover"];
        description = "start without displaying cover art";
      };
      NoUi = {
        args = ["--noui"];
        description = "play without displaying the user interface";
      };
      Path = {
        args = ["path"];
        description = "set the music library path";
      };
      Play = {
        args = ["play"];
        description = "play one or more file or directory paths";
      };
      QuitOnStop = {
        args = ["--quitonstop"];
        description = "exit after the playlist finishes";
      };
      Shuffle = {
        args = ["shuffle"];
        description = "shuffle a matching song or album playlist";
      };
      Song = {
        args = ["song"];
        description = "find and play a song by name";
      };
      Theme = {
        args = ["theme"];
        description = "set the interface theme";
      };
      Verbose = {
        args = ["--verbose"];
        description = "log additional diagnostic information";
      };
      Version = {
        args = ["--version"];
        description = "show the installed version";
      };
    };
  };

  jaq = mkSource {
    categories = ["text" "scripting"];
    description = "jq-compatible JSON processor (Rust)";
    aliases = mkAliasFamily "jaq" {
      c = {
        args = ["-c"];
        description = "output compact JSON";
      };
      f = {
        args = ["--from-file"];
        description = "read the filter from a file";
      };
      n = {
        args = ["-n"];
        description = "run without reading input";
      };
      r = {
        args = ["-r"];
        description = "output strings without JSON quotes";
      };
      na = {
        args = ["-n" "--arg"];
        description = "run without input and bind a caller-specified string argument";
      };
      RawInput = {
        args = ["-R"];
        description = "read each input line as a string";
      };
      Rr = {
        args = ["-Rr"];
        description = "read raw input lines and output raw strings";
      };
      s = {
        args = ["-s"];
        description = "read all inputs into a single array";
      };
    };
  };

  jq = mkSource {
    categories = ["text" "scripting"];
    description = "command-line JSON processor";
    aliases = mkAliasFamily "jq" {
      c = {
        args = ["-c"];
        description = "output compact JSON";
      };
      e = {
        args = ["-e"];
        description = "set the exit status from the last output value";
      };
      f = {
        args = ["--from-file"];
        description = "read the filter from a file";
      };
      j = {
        args = ["-j"];
        description = "output raw strings without trailing newlines";
      };
      n = {
        args = ["-n"];
        description = "run without reading input";
      };
      na = {
        args = ["-n" "--arg"];
        description = "run without input and bind a caller-specified string argument";
      };
      r = {
        args = ["-r"];
        description = "output strings without JSON quotes";
      };
      RawInput = {
        args = ["-R"];
        description = "read each input line as a string";
      };
      Rr = {
        args = ["-Rr"];
        description = "read raw input lines and output raw strings";
      };
      Rs = {
        args = ["-Rs"];
        description = "read all input as a single raw string";
      };
      s = {
        args = ["-s"];
        description = "read all inputs into a single array";
      };
      SortKeys = {
        args = ["--sort-keys"];
        description = "output object keys in sorted order";
      };
    };
  };

  libnotify = mkSource {
    categories = ["desktop-cli" "scripting"];
    description = "desktop notifications";
    exe = "notify-send";
    aliases = mergeDisjoint [
      (mkAliasFamily "notify-send" {
        aliasPrefix = "notify";
        App = {
          args = ["--app-name"];
          description = "send a notification under a caller-specified application name";
        };
        Critical = {
          args = ["--urgency=critical"];
          description = "send a critical-urgency notification";
        };
        Expire = {
          args = ["--expire-time"];
          description = "send a notification that expires after a caller-specified time in milliseconds";
        };
        Icon = {
          args = ["--icon"];
          description = "send a notification with a caller-specified icon";
        };
        Transient = {
          args = ["--transient"];
          description = "send a notification that is not kept in notification history";
        };
      })
    ];
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

  mpv = mkSource {
    categories = ["media" "video"];
    description = "versatile command-line media player";
    aliases = mkAliasFamily "mpv" {
      Audio = {
        args = ["--no-video"];
        description = "play media as audio without displaying video";
      };
      Fullscreen = {
        args = ["--fullscreen"];
        description = "start playback in fullscreen mode";
      };
      Help = {
        args = ["--help"];
        description = "show command-line help";
      };
      Loop = {
        args = ["--loop-file=inf"];
        description = "repeat each played file indefinitely";
      };
      Playlist = {
        args = ["--playlist"];
        description = "play entries from a playlist file";
      };
      Version = {
        args = ["--version"];
        description = "show the installed version";
      };
    };
  };

  nemo = mkSource {
    categories = ["desktop-ui"];
    description = "Nemo file manager with extensions";
    target = "nemo-with-extensions";
    exe = "nemo";
  };

  ouch = mkSource {
    categories = ["archives" "scripting"];
    description = "unified archive compressor and decompressor for tar, zip, 7z, gz, xz, zst, and more";
    aliases = mergeDisjoint [
      (mkAliasFamily "ouch" {
        aliasPrefix = "";
        lsar = {
          args = ["list"];
          description = "list archive contents";
        };
        lsarTree = {
          args = ["list" "--tree"];
          description = "list archive contents as a tree";
        };
        pack = {
          args = ["compress"];
          description = "compress files into an archive";
        };
        packYes = {
          args = ["compress" "--yes"];
          description = "compress files, overwriting existing output without asking";
        };
        unpack = {
          args = ["decompress"];
          description = "decompress an archive";
        };
        unpackTo = {
          args = ["decompress" "--dir"];
          description = "decompress into a caller-specified directory";
        };
        unpackYes = {
          args = ["decompress" "--yes"];
          description = "decompress, overwriting existing files without asking";
        };
      })
    ];
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

  quickshell = mkSource {
    categories = ["desktop-ui"];
    description = "QtQuick-based desktop shell";
    input = "quickshell";
    aliases = mkAliasFamily "quickshell" {
      Config = {
        args = ["--config"];
        description = "start a named configuration (caller supplies it)";
      };
      Kill = {
        args = ["kill"];
        description = "stop a running quickshell instance";
      };
      List = {
        args = ["list"];
        description = "list running quickshell instances";
      };
      Path = {
        args = ["--path"];
        description = "start from a caller-specified configuration path";
      };
    };
  };

  ripgrep = mkSource {
    categories = ["text" "scripting"];
    description = "fast recursive grep (rg)";
    aliases = mkAliasFamily "rg" {
      i = {
        args = ["-i"];
        description = "search case-insensitively";
      };
      "0" = {
        args = ["--null"];
        description = "separate matching paths with NUL bytes";
      };
      c = {
        args = ["--count"];
        description = "count matching lines per file";
      };
      Context = {
        args = ["--context"];
        description = "show a caller-specified number of context lines around matches";
      };
      F = {
        args = ["--fixed-strings"];
        description = "match literal strings instead of regular expressions";
      };
      Files = {
        args = ["--files"];
        description = "list files that would be searched";
      };
      FilesWithout = {
        args = ["--files-without-match"];
        description = "list files that contain no matches";
      };
      Fxq = {
        args = ["-Fxq"];
        description = "quietly search for an exact fixed-string line";
      };
      g = {
        args = ["--glob"];
        description = "include or exclude paths with a caller-specified glob";
      };
      h = {
        args = ["--hidden" "--no-ignore"];
        description = "search including hidden and ignored paths";
      };
      j = {
        args = ["--json"];
        description = "output matches as JSON lines";
      };
      l = {
        args = ["--files-with-matches"];
        description = "print only the names of files with matches";
      };
      m = {
        args = ["--multiline"];
        description = "allow matches to span multiple lines";
      };
      o = {
        args = ["--only-matching"];
        description = "print only the matching part of each line";
      };
      q = {
        args = ["-q"];
        description = "search quietly and report success through the exit status";
      };
      t = {
        args = ["--type"];
        description = "search only a caller-specified file type";
      };
      TypeNot = {
        args = ["--type-not"];
        description = "skip a caller-specified file type";
      };
      v = {
        args = ["--invert-match"];
        description = "show lines that do not match";
      };
      w = {
        args = ["--word-regexp"];
        description = "match whole words only";
      };
    };
  };

  sd = mkSource {
    categories = ["text" "scripting"];
    description = "intuitive sed alternative";
    aliases = mkAliasFamily "sd" {
      f = {
        args = ["--flags"];
        description = "set regex flags such as i or m (caller supplies them)";
      };
      p = {
        args = ["--preview"];
        description = "preview replacements without writing files";
      };
      s = {
        args = ["--string-mode"];
        description = "treat the pattern as a literal string";
      };
    };
  };

  swaybg = mkSource {
    categories = ["desktop-ui"];
    description = "wallpaper utility for Sway";
    aliases = mkAliasFamily "swaybg" {
      Color = {
        args = ["--color"];
        description = "set a solid background color (caller supplies it)";
      };
      Fill = {
        args = ["--mode" "fill" "--image"];
        description = "set an image wallpaper scaled to fill the output (caller supplies the image)";
      };
      Image = {
        args = ["--image"];
        description = "set an image wallpaper (caller supplies the image)";
      };
    };
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

  tree = mkSource {
    categories = ["core" "scripting"];
    description = "list directory contents as a tree";
    aliases = mkAliasFamily "tree" {
      a = {
        args = ["-a"];
        description = "include hidden files";
      };
      d = {
        args = ["-d"];
        description = "list directories only";
      };
      f = {
        args = ["-f"];
        description = "print the full path prefix for each entry";
      };
      h = {
        args = ["-h"];
        description = "show human-readable sizes";
      };
      I = {
        args = ["-I"];
        description = "exclude entries matching a caller-specified pattern";
      };
      J = {
        args = ["-J"];
        description = "output the tree as JSON";
      };
      L = {
        args = ["-L"];
        description = "limit the display depth";
      };
      p = {
        args = ["--prune"];
        description = "omit empty directories";
      };
    };
  };

  treefmt = mkSource {
    categories = ["formatters" "scripting"];
    description = "multi-language code formatter";
    input = "treefmt";
    target = "treefmt";
    exe = "treefmt";
  };

  lsd = mkSource {
    categories = ["files" "scripting"];
    description = "file listing with colours and icons";
    aliases = let
      cfg = {
        default = {
          args = ["--icon=auto" "--color=auto"];
          description = "with sane defaults";
        };
        plain = {
          args = ["--icon=never" "--color=never" "--oneline"];
          description = "with plain output, one entry per line";
        };
        hidden = {
          args = ["--almost-all"];
          description = "with hidden files";
        };
        info = {
          args = ["--long" "--git"];
          description = "with metadata columns";
        };
        tree = {
          args = ["--tree"];
          description = "with tree output";
        };
        recursive = {
          args = ["--recursive"];
          description = "with recursive output";
        };
        dirs = {
          args = ["--directory-only"];
          description = "listing only directories";
        };
        depth = {
          trailing = ["--depth"];
          description = "limited to a required depth";
        };
      };
      mkLsd = mkLayeredAlias "lsd" [cfg.default];
      mkViewAlias = name: view: let
        mkPlain = extra: mkLsd ([view cfg.plain] ++ extra);
      in {
        ${name} = mkLsd [view cfg.info];
        "${name}a" = mkLsd [view cfg.hidden];
        "${name}p" = mkPlain [];
        "${name}pa" = mkPlain [cfg.hidden];
        "${name}ap" = mkPlain [cfg.hidden];
      };
      mkRecursiveAlias = name: mode:
        mkViewAlias name {
          inherit (mode) args;
          inherit (cfg.depth) trailing;
          description = "${mode.description}, ${cfg.depth.description}";
        };
      mkSortAlias = name: by:
        mkViewAlias name {
          args = ["--sort=${by}"];
          description = "list sorted by ${by}";
        };
    in
      mergeDisjoint (
        [
          {
            lsdLong = mkLsd [cfg.info cfg.hidden];
            lsdTree = mkLsd [cfg.tree];
            lsdRecursive = mkLsd [cfg.info cfg.recursive];
          }
        ]
        ++ [
          (mkViewAlias "lsdl" {})
          (mkViewAlias "lsdd" cfg.dirs)
          (mkViewAlias "lsdt" cfg.tree)
          (mkViewAlias "lsdr" cfg.recursive)
          (mkRecursiveAlias "lt" cfg.tree)
          (mkRecursiveAlias "lr" cfg.recursive)
        ]
        ++ mapAttrsToList mkSortAlias {
          lsds = "size";
          lsdm = "time";
          lsdv = "version";
          lsde = "extension";
          lsdGit = "git";
          lsdNone = "none";
        }
      );
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

  variety = mkSource {
    categories = ["desktop-ui"];
    description = "wallpaper changer with scheduling and effects";
    aliases = mkAliasFamily "variety" {
      Favorite = {
        args = ["--favorite"];
        description = "move the current wallpaper to favorites";
      };
      Next = {
        args = ["--next"];
        description = "switch to the next wallpaper";
      };
      Preferences = {
        args = ["--preferences"];
        description = "open the preferences window";
      };
      Previous = {
        args = ["--previous"];
        description = "switch to the previous wallpaper";
      };
      Quit = {
        args = ["--quit"];
        description = "quit the running instance";
      };
      TogglePause = {
        args = ["--toggle-pause"];
        description = "pause or resume wallpaper changes";
      };
      Trash = {
        args = ["--trash"];
        description = "move the current wallpaper to the trash";
      };
    };
  };

  vscode-fhs = mkSource {
    categories = ["editors"];
    description = "VS Code (FHS environment)";
    aliases = mkAliasFamily "code" {
      Add = {
        args = ["--add"];
        description = "add a folder to the last active window";
      };
      Diff = {
        args = ["--diff"];
        description = "compare two files";
      };
      ExtInstall = {
        args = ["--install-extension"];
        description = "install an extension (caller supplies its identifier)";
      };
      ExtList = {
        args = ["--list-extensions"];
        description = "list installed extensions";
      };
      Goto = {
        args = ["--goto"];
        description = "open a file at a caller-specified line and column (file:line:column)";
      };
      New = {
        args = ["--new-window"];
        description = "open in a new window";
      };
      Reuse = {
        args = ["--reuse-window"];
        description = "open in the last active window";
      };
      Safe = {
        args = ["--disable-extensions"];
        description = "start with all extensions disabled";
      };
      Wait = {
        args = ["--wait"];
        description = "wait for the file to be closed before returning";
      };
    };
  };

  vscode-insiders = mkSource {
    categories = ["editors"];
    description = "VS Code Insiders";
    input = "vscode-insiders";
    exe = "code-insiders";
    aliases = mergeDisjoint [
      (mkAliasFamily "code-insiders" {
        aliasPrefix = "codeInsiders";
        Diff = {
          args = ["--diff"];
          description = "compare two files";
        };
        ExtInstall = {
          args = ["--install-extension"];
          description = "install an extension (caller supplies its identifier)";
        };
        ExtList = {
          args = ["--list-extensions"];
          description = "list installed extensions";
        };
        Goto = {
          args = ["--goto"];
          description = "open a file at a caller-specified line and column (file:line:column)";
        };
        New = {
          args = ["--new-window"];
          description = "open in a new window";
        };
        Wait = {
          args = ["--wait"];
          description = "wait for the file to be closed before returning";
        };
      })
    ];
  };

  wl-clipboard = mkSource {
    categories = ["desktop-cli" "scripting"];
    description = "wl-copy, wl-paste, and related Wayland clipboard tools";
    discover = true; #? wl-copy, wl-paste
    exe = "wl-copy";
    aliases = mergeDisjoint [
      (mkAliasFamily "wl-copy" {
        aliasPrefix = "wlCopy";
        Clear = {
          args = ["--clear"];
          description = "clear the clipboard";
        };
        Primary = {
          args = ["--primary"];
          description = "copy to the primary selection";
        };
        Trim = {
          args = ["--trim-newline"];
          description = "copy without the trailing newline";
        };
        Type = {
          args = ["--type"];
          description = "copy using a caller-specified MIME type";
        };
      })
      (mkAliasFamily "wl-paste" {
        aliasPrefix = "wlPaste";
        List = {
          args = ["--list-types"];
          description = "list the MIME types available on the clipboard";
        };
        NoNewline = {
          args = ["--no-newline"];
          description = "paste without adding a trailing newline";
        };
        Primary = {
          args = ["--primary"];
          description = "paste from the primary selection";
        };
        Type = {
          args = ["--type"];
          description = "paste a caller-specified MIME type";
        };
        Watch = {
          args = ["--watch"];
          description = "run a command each time the clipboard changes";
        };
      })
    ];
  };

  xdg-utils = mkSource {
    categories = ["desktop-cli" "scripting"];
    description = "xdg-open, xdg-mime, and related desktop integration tools";
    discover = true; #? xdg-open, xdg-mime, ...
    exe = "xdg-open";
    aliases = mergeDisjoint [
      (mkAliasFamily "xdg-settings" {
        aliasPrefix = "xdg";
        BrowserGet = {
          args = ["get" "default-web-browser"];
          description = "show the default web browser";
        };
        BrowserSet = {
          args = ["set" "default-web-browser"];
          description = "set the default web browser (caller supplies the .desktop file)";
        };
        SettingsGet = {
          args = ["get"];
          description = "read a desktop setting";
        };
        SettingsSet = {
          args = ["set"];
          description = "change a desktop setting";
        };
      })
      (mkAliasFamily "xdg-mime" {
        aliasPrefix = "xdgMime";
        Default = {
          args = ["default"];
          description = "set the default application for a MIME type (caller supplies both)";
        };
        QueryDefault = {
          args = ["query" "default"];
          description = "show the default application for a MIME type";
        };
        QueryFiletype = {
          args = ["query" "filetype"];
          description = "show the MIME type of a file";
        };
      })
    ];
  };

  yazi = let
    #? Expanded by the shell at run time, so they follow the current user/host.
    #? `\${` stops Nix from interpolating.
    roots = {
      projects = "\${PROJECTS:-$HOME/Projects}";
      cc = "\${PRJ_CC:-$HOME/Projects/craole-cc}";
      dots = "\${DOTS:-$HOME/.dots}";
      yazi = "\${XDG_CONFIG_HOME:-$HOME/.config}/yazi";
    };
  in
    mkSource {
      categories = ["files" "scripting"];
      description = "terminal file manager";
      aliases = let
        cfg = {
          projects = {
            args = [roots.projects];
            description = "open yazi in the projects root";
          };
          cc = {
            args = [roots.cc];
            description = "open yazi in the craole-cc projects";
          };
          dots = {
            args = [roots.dots];
            description = "open yazi in the dotfiles";
          };
          yazi = {
            args = [roots.yazi];
            description = "open yazi in its own config directory";
          };
          chooserFile = {
            trailing = ["--chooser-file"];
            description = "write the selected file path to a caller-supplied file";
          };
          cwdFile = {
            trailing = ["--cwd-file"];
            description = "write the final working directory to a caller-supplied file";
          };
          select = {
            trailing = ["--select"];
            description = "select a caller-supplied file on startup";
          };
        };
        mkYazi = mkLayeredAlias "yazi" [];
        mkRootAliases = names: root:
          mergeDisjoint (map (name: {${name} = mkYazi [root];}) names);
      in
        mergeDisjoint [
          (mkRootAliases ["f" "y" "yz"] {})
          (mkRootAliases ["yp" "yaziProjects"] cfg.projects)
          (mkRootAliases ["yc" "yaziCC"] cfg.cc)
          (mkRootAliases ["yd" "yaziDots"] cfg.dots)
          (mkRootAliases ["yy" "yaziYazi"] cfg.yazi)
          (mkAliasFamily "yazi" {
            ChooserFile = {
              inherit (cfg.chooserFile) description;
              args = cfg.chooserFile.trailing;
            };
            CwdFile = {
              inherit (cfg.cwdFile) description;
              args = cfg.cwdFile.trailing;
            };
            Select = {
              inherit (cfg.select) description;
              args = cfg.select.trailing;
            };
          })
        ];
    };

  yq-go = mkSource {
    categories = ["text" "scripting"];
    description = "portable YAML, JSON, and XML processor (Go)";
    aliases = mkAliasFamily "yq" {
      e = {
        args = ["eval"];
        description = "evaluate an expression against each file separately";
      };
      ea = {
        args = ["eval-all"];
        description = "evaluate an expression against all files together";
      };
      i = {
        args = ["--inplace"];
        description = "edit files in place";
      };
      JsonToYaml = {
        args = ["--input-format" "json" "--output-format" "yaml"];
        description = "convert JSON to YAML";
      };
      Merge = {
        args = ["eval-all" "select(fileIndex == 0) * select(fileIndex == 1)"];
        description = "deep-merge two files, with the second taking precedence";
      };
      n = {
        args = ["--null-input"];
        description = "run without reading input";
      };
      P = {
        args = ["--prettyPrint"];
        description = "pretty-print the output";
      };
      ToJson = {
        args = ["--output-format" "json"];
        description = "convert YAML to JSON";
      };
    };
  };
}
