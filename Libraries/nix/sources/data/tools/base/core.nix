{
  mkAlias,
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
}
