# Every source is declared once, tagged with the group it belongs to.
# `group` and `aliases` are ours (stripped before pkgsFrom sees them); the
# other keys (discover, exe, input) are passed through unchanged.
let
  mkSource = {
    categories,
    description,
    ...
  } @ source:
    source // {inherit categories description;};

  # Binds the command once; each alias then only states its args:
  #   bat = mkAlias "bat";
  #   batn = bat {args = ["--number"]; description = "show line numbers";};
  # The result is still {cmd, description} with cmd = [command] ++ args.
  mkAlias = command: {
    args,
    description ? null,
  }: {
    cmd = [command] ++ args;
    inherit description;
  };
in {
  alejandra = mkSource {
    categories = ["formatters" "scripting"];
    description = "opinionated Nix formatter";
    aliases = let
      mk = mkAlias "alejandra";
    in {
      aljCheck = mk {
        args = ["--check"];
        description = "check formatting without changing files";
      };
      aljQuiet = mk {
        args = ["--quiet"];
        description = "format files without printing progress output";
      };
      aljHere = mk {
        args = ["."];
        description = "format every Nix file under the current directory";
      };
    };
  };

  bash = mkSource {
    categories = ["shells" "scripting"];
    description = "Bourne-again shell";
    aliases = let
      mk = mkAlias "bash";
    in {
      bashc = mk {
        args = ["-c"];
        description = "run a command string";
      };
      bashn = mk {
        args = ["-n"];
        description = "check a script's syntax without running it";
      };
      bashx = mk {
        args = ["-x"];
        description = "run a script while tracing each command";
      };
      bashStrict = mk {
        args = ["-euo" "pipefail"];
        description = "run a script with strict error handling";
      };
    };
  };

  bat = mkSource {
    categories = ["files" "scripting"];
    description = "cat with syntax highlighting";
    aliases = let
      mk = mkAlias "bat";
    in {
      batd = mk {
        args = ["--diff"];
        description = "show only lines changed relative to the git index";
      };
      batl = mk {
        args = ["--language"];
        description = "force a syntax language (caller supplies it)";
      };
      batn = mk {
        args = ["--number"];
        description = "show line numbers";
      };
      batp = mk {
        args = ["--plain"];
        description = "print without decorations or syntax highlighting";
      };
      batpp = mk {
        args = ["-pp"];
        description = "print plain without paging";
      };
      batr = mk {
        args = ["--line-range"];
        description = "print only a caller-specified line range";
      };
    };
  };

  biome = mkSource {
    categories = ["formatters" "scripting"];
    description = "fast formatter and linter for JS, TS, JSON, and CSS";
    aliases = let
      mk = mkAlias "biome";
    in {
      biomeCheck = mk {
        args = ["check"];
        description = "run the formatter, linter, and import sorting checks";
      };
      biomeFix = mk {
        args = ["check" "--write"];
        description = "run all checks and apply safe fixes";
      };
      biomeCI = mk {
        args = ["ci"];
        description = "run read-only checks suited to CI";
      };
      biomeFormat = mk {
        args = ["format" "--write"];
        description = "format files in place";
      };
      biomeLint = mk {
        args = ["lint"];
        description = "lint files without changing them";
      };
    };
  };

  coreutils = mkSource {
    categories = ["core" "scripting"];
    description = "core file, text, and shell utilities";
    discover = true;
    aliases = let
      mkBase64 = mkAlias "base64";
      mkChmod = mkAlias "chmod";
      mkChown = mkAlias "chown";
      mkCp = mkAlias "cp";
      mkCut = mkAlias "cut";
      mkDate = mkAlias "date";
      mkDf = mkAlias "df";
      mkDu = mkAlias "du";
      mkEcho = mkAlias "echo";
      mkEnv = mkAlias "env";
      mkHead = mkAlias "head";
      mkInstall = mkAlias "install";
      mkLn = mkAlias "ln";
      mkMkdir = mkAlias "mkdir";
      mkMktemp = mkAlias "mktemp";
      mkMv = mkAlias "mv";
      mkNumfmt = mkAlias "numfmt";
      mkPaste = mkAlias "paste";
      mkReadlink = mkAlias "readlink";
      mkRealpath = mkAlias "realpath";
      mkRm = mkAlias "rm";
      mkRmdir = mkAlias "rmdir";
      mkSeq = mkAlias "seq";
      mkSha = mkAlias "sha256sum";
      mkSort = mkAlias "sort";
      mkStat = mkAlias "stat";
      mkTail = mkAlias "tail";
      mkTee = mkAlias "tee";
      mkTouch = mkAlias "touch";
      mkTr = mkAlias "tr";
      mkTruncate = mkAlias "truncate";
      mkUniq = mkAlias "uniq";
      mkWc = mkAlias "wc";
    in {
      base64d = mkBase64 {
        args = ["--decode"];
        description = "decode base64 input";
      };
      base64w0 = mkBase64 {
        args = ["--wrap=0"];
        description = "encode base64 without line wrapping";
      };
      chmod0600 = mkChmod {
        args = ["0600"];
        description = "set permissions to 0600";
      };
      chmod0644 = mkChmod {
        args = ["0644"];
        description = "set permissions to 0644";
      };
      chmod0755 = mkChmod {
        args = ["0755"];
        description = "set permissions to 0755";
      };
      chmodR = mkChmod {
        args = ["-R"];
        description = "change permissions recursively";
      };
      chmodRef = mkChmod {
        args = ["--reference"];
        description = "copy permissions from a reference file (caller supplies it)";
      };
      chmodRuw = mkChmod {
        args = ["-R" "u+w"];
        description = "recursively add owner write permission";
      };
      chmodx = mkChmod {
        args = ["+x"];
        description = "make files executable";
      };
      chownR = mkChown {
        args = ["-R"];
        description = "change ownership recursively";
      };
      cpa = mkCp {
        args = ["-a" "--reflink=auto"];
        description = "copy recursively, preserving attributes and using reflinks when possible";
      };
      cpaf = mkCp {
        args = ["-af" "--reflink=auto"];
        description = "force-copy recursively, preserving attributes and using reflinks when possible";
      };
      cutd = mkCut {
        args = ["-d"];
        description = "cut using a caller-specified delimiter";
      };
      cutf = mkCut {
        args = ["-f"];
        description = "select caller-specified fields";
      };
      dateEpoch = mkDate {
        args = ["+%s"];
        description = "print the current Unix timestamp in seconds";
      };
      dateI = mkDate {
        args = ["-I"];
        description = "print the date in ISO format";
      };
      dateIs = mkDate {
        args = ["-Is"];
        description = "print the date and time in ISO format";
      };
      dateu = mkDate {
        args = ["-u"];
        description = "print the date and time in UTC";
      };
      dfh = mkDf {
        args = ["-h"];
        description = "show filesystem usage in human-readable sizes";
      };
      dush = mkDu {
        args = ["-sh"];
        description = "show the total human-readable size of each argument";
      };
      echon = mkEcho {
        args = ["-n"];
        description = "print without a trailing newline";
      };
      envi = mkEnv {
        args = ["-i"];
        description = "run a command with an empty environment";
      };
      envu = mkEnv {
        args = ["-u"];
        description = "run a command with a caller-specified variable unset";
      };
      headc = mkHead {
        args = ["-c"];
        description = "print the first caller-specified number of bytes";
      };
      headn = mkHead {
        args = ["-n"];
        description = "print the first caller-specified number of lines";
      };
      installD = mkInstall {
        args = ["-D"];
        description = "install a file and create missing parent directories";
      };
      installDm = mkInstall {
        args = ["-D" "-m"];
        description = "install with caller-specified permissions and create parent directories";
      };
      install0644 = mkInstall {
        args = ["-D" "-m" "0644"];
        description = "install with 0644 permissions and create parent directories";
      };
      install0600 = mkInstall {
        args = ["-D" "-m" "0600"];
        description = "install with 0600 permissions and create parent directories";
      };
      install0755 = mkInstall {
        args = ["-D" "-m" "0755"];
        description = "install with 0755 permissions and create parent directories";
      };
      installm = mkInstall {
        args = ["-m"];
        description = "install with caller-specified permissions";
      };
      lnsf = mkLn {
        args = ["-sf"];
        description = "create or replace a symbolic link";
      };
      lnsfn = mkLn {
        args = ["-sfn"];
        description = "create or replace a symbolic link, treating the destination as a file";
      };
      lnsr = mkLn {
        args = ["-sr"];
        description = "create a symbolic link with a path relative to the link location";
      };
      mkdirp = mkMkdir {
        args = ["-p"];
        description = "create directories and any missing parents";
      };
      mkdirpv = mkMkdir {
        args = ["-pv"];
        description = "create directories and any missing parents, printing each one";
      };
      mktempd = mkMktemp {
        args = ["-d"];
        description = "create a temporary directory";
      };
      mvt = mkMv {
        args = ["-T"];
        description = "move without treating the destination as a directory";
      };
      mvf = mkMv {
        args = ["-f"];
        description = "move files, replacing existing destinations without prompting";
      };
      mvn = mkMv {
        args = ["--no-clobber"];
        description = "move files without overwriting existing destinations";
      };
      numfmtIec = mkNumfmt {
        args = ["--to=iec"];
        description = "convert byte counts to human-readable IEC sizes";
      };
      pasted = mkPaste {
        args = ["-d"];
        description = "merge lines using a caller-specified delimiter";
      };
      readlinkf = mkReadlink {
        args = ["-f"];
        description = "print the canonical absolute path of a file";
      };
      readlinkm = mkReadlink {
        args = ["-m"];
        description = "print the canonical path without requiring components to exist";
      };
      realpathRel = mkRealpath {
        args = ["--relative-to"];
        description = "print a path relative to a caller-specified base";
      };
      rmf = mkRm {
        args = ["-f"];
        description = "remove files without prompting or failing on missing ones";
      };
      rmr = mkRm {
        args = ["-r"];
        description = "remove directories recursively";
      };
      rmrf = mkRm {
        args = ["-rf"];
        description = "remove files and directories recursively without prompting";
      };
      rmdirp = mkRmdir {
        args = ["-p"];
        description = "remove a directory and its empty parents";
      };
      seqw = mkSeq {
        args = ["-w"];
        description = "print a number sequence padded with leading zeros";
      };
      sha256sumc = mkSha {
        args = ["--check"];
        description = "verify SHA-256 checksums from a file";
      };
      sortn = mkSort {
        args = ["-n"];
        description = "sort lines by numeric value";
      };
      sortnr = mkSort {
        args = ["-nr"];
        description = "sort lines by numeric value, largest first";
      };
      sortk = mkSort {
        args = ["-k"];
        description = "sort by a caller-specified key";
      };
      sortr = mkSort {
        args = ["-r"];
        description = "sort lines in reverse order";
      };
      sortu = mkSort {
        args = ["-u"];
        description = "sort lines and remove duplicates";
      };
      sortV = mkSort {
        args = ["-V"];
        description = "sort lines by version number";
      };
      statc = mkStat {
        args = ["-c"];
        description = "print file status using a caller-specified format";
      };
      tailc = mkTail {
        args = ["-c"];
        description = "print the caller-specified number of trailing bytes";
      };
      tailF = mkTail {
        args = ["-F"];
        description = "follow a file by name and continue after log rotation";
      };
      tailn = mkTail {
        args = ["-n"];
        description = "print the caller-specified number of trailing lines";
      };
      teea = mkTee {
        args = ["-a"];
        description = "append standard input to files and pass it to standard output";
      };
      touchd = mkTouch {
        args = ["-d"];
        description = "set file times to a caller-specified date";
      };
      touchr = mkTouch {
        args = ["-r"];
        description = "copy file times from a reference file";
      };
      trd = mkTr {
        args = ["-d"];
        description = "delete caller-specified characters";
      };
      trs = mkTr {
        args = ["-s"];
        description = "squeeze repeated characters into one";
      };
      truncateS = mkTruncate {
        args = ["-s"];
        description = "set a file to a caller-specified size";
      };
      uniqc = mkUniq {
        args = ["-c"];
        description = "count adjacent duplicate lines";
      };
      uniqd = mkUniq {
        args = ["-d"];
        description = "print only duplicated lines";
      };
      wcc = mkWc {
        args = ["-c"];
        description = "count bytes";
      };
      wcl = mkWc {
        args = ["-l"];
        description = "count lines";
      };
      wcw = mkWc {
        args = ["-w"];
        description = "count words";
      };
    };
  };

  curl = mkSource {
    categories = ["networking" "scripting"];
    description = "transfer data with URLs";
    aliases = let
      mk = mkAlias "curl";
    in {
      curlfsSL = mk {
        args = ["-fsSL"];
        description = "fetch quietly, follow redirects, and fail on HTTP errors";
      };
      curlI = mk {
        args = ["--head"];
        description = "fetch response headers only";
      };
      curlJson = mk {
        args = ["-fsSL" "-H" "Accept: application/json"];
        description = "fetch quietly while requesting a JSON response";
      };
      curlL = mk {
        args = ["--location"];
        description = "follow redirects";
      };
      curlO = mk {
        args = ["--remote-name"];
        description = "save the download using its remote file name";
      };
      curlOutput = mk {
        args = ["--output"];
        description = "save the download to a caller-specified path";
      };
      curlRetry = mk {
        args = ["-fsSL" "--retry" "3" "--retry-delay" "2"];
        description = "fetch quietly and retry transient failures up to three times";
      };
    };
  };

  dash = mkSource {
    categories = ["shells" "scripting"];
    description = "lightweight POSIX sh for `write.posix` shebangs";
    aliases = let
      mk = mkAlias "dash";
    in {
      dashc = mk {
        args = ["-c"];
        description = "run a command string with POSIX sh";
      };
      dashn = mk {
        args = ["-n"];
        description = "check a script's syntax without running it";
      };
      dashx = mk {
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
    aliases = let
      mkDbusMonitor = mkAlias "dbus-monitor";
      mkDbusSend = mkAlias "dbus-send";
    in {
      dbusMonitorSession = mkDbusMonitor {
        args = ["--session"];
        description = "watch messages on the session bus";
      };
      dbusMonitorSystem = mkDbusMonitor {
        args = ["--system"];
        description = "watch messages on the system bus";
      };
      dbusSessionCall = mkDbusSend {
        args = ["--session" "--print-reply" "--type=method_call" "--dest"];
        description = "call a session bus method and print the reply (caller supplies destination, path, and method)";
      };
      dbusSystemCall = mkDbusSend {
        args = ["--system" "--print-reply" "--type=method_call" "--dest"];
        description = "call a system bus method and print the reply (caller supplies destination, path, and method)";
      };
    };
  };

  diffutils = mkSource {
    categories = ["core" "scripting"];
    description = "cmp, diff, diff3, and sdiff";
    discover = true; #? cmp, diff, diff3, sdiff
    exe = "cmp";
    aliases = let
      mkCmp = mkAlias "cmp";
      mkDiff = mkAlias "diff";
    in {
      cmpl = mkCmp {
        args = ["-l"];
        description = "list every differing byte";
      };
      cmps = mkCmp {
        args = ["-s"];
        description = "compare files without printing differences";
      };
      diffq = mkDiff {
        args = ["-q"];
        description = "report only whether files differ";
      };
      diffu = mkDiff {
        args = ["-u"];
        description = "show differences in unified format";
      };
      diffur = mkDiff {
        args = ["-ur"];
        description = "show recursive differences in unified format";
      };
      diffurN = mkDiff {
        args = ["-urN"];
        description = "show recursive unified differences, treating absent files as empty";
      };
      diffy = mkDiff {
        args = ["--side-by-side"];
        description = "show differences side by side";
      };
    };
  };

  dms-shell = mkSource {
    categories = ["desktop-ui"];
    description = "Dank Material Shell";
    input = "dank-material-shell";
  };

  dprint = mkSource {
    categories = ["formatters" "scripting"];
    description = "pluggable multi-language code formatter";
    aliases = let
      mk = mkAlias "dprint";
    in {
      dprintCheck = mk {
        args = ["check"];
        description = "check formatting without changing files";
      };
      dprintFmt = mk {
        args = ["fmt"];
        description = "format files in place";
      };
      dprintInit = mk {
        args = ["init"];
        description = "create a dprint configuration file";
      };
    };
  };

  dust = mkSource {
    categories = ["files" "scripting"];
    description = "intuitive du (disk usage)";
    aliases = let
      mk = mkAlias "dust";
    in {
      dustd = mk {
        args = ["-d"];
        description = "limit the directory depth shown";
      };
      dustDirs = mk {
        args = ["-D"];
        description = "show only directories";
      };
      dustn = mk {
        args = ["-n"];
        description = "show a caller-specified number of entries";
      };
      dustr = mk {
        args = ["-r"];
        description = "show the largest entries at the bottom";
      };
    };
  };

  eza = mkSource {
    categories = ["files" "scripting"];
    description = "modern ls replacement";
    aliases = let
      mk = mkAlias "eza";
    in {
      ezaa = mk {
        args = ["--all"];
        description = "list all files including hidden ones";
      };
      ezaDirs = mk {
        args = ["--only-dirs"];
        description = "list only directories";
      };
      ezal = mk {
        args = ["--long"];
        description = "list in long format";
      };
      ezala = mk {
        args = ["--long" "--all"];
        description = "list all files in long format";
      };
      ezalg = mk {
        args = ["--long" "--git"];
        description = "list in long format with git status";
      };
      ezam = mk {
        args = ["--long" "--sort=modified"];
        description = "list in long format, oldest first";
      };
      ezas = mk {
        args = ["--long" "--sort=size"];
        description = "list in long format, smallest first";
      };
      ezat = mk {
        args = ["--tree"];
        description = "list as a tree";
      };
      ezatl = mk {
        args = ["--tree" "--level"];
        description = "list as a tree limited to a caller-specified depth";
      };
    };
  };

  fd = mkSource {
    categories = ["files" "scripting"];
    description = "simple, fast find alternative";
    aliases = let
      mk = mkAlias "fd";
    in {
      fd0 = mk {
        args = ["--print0"];
        description = "separate results with NUL bytes";
      };
      fdd = mk {
        args = ["--type" "d"];
        description = "find directories only";
      };
      fde = mk {
        args = ["--extension"];
        description = "find files with a caller-specified extension";
      };
      fdExecBatch = mk {
        args = ["--exec-batch"];
        description = "run one command with all results as arguments";
      };
      fdf = mk {
        args = ["--type" "f"];
        description = "find regular files only";
      };
      fdg = mk {
        args = ["--glob"];
        description = "match with a glob pattern instead of a regex";
      };
      fdh = mk {
        args = ["--hidden" "--no-ignore"];
        description = "find files including hidden and ignored paths";
      };
      fdmd = mk {
        args = ["--max-depth"];
        description = "limit the search depth";
      };
      fdx = mk {
        args = ["--exec"];
        description = "run a command once for each result";
      };
    };
  };

  file = mkSource {
    categories = ["core" "scripting"];
    description = "determine file type";
    aliases = let
      mk = mkAlias "file";
    in {
      fileb = mk {
        args = ["--brief"];
        description = "print the file type without the file name";
      };
      fileL = mk {
        args = ["--dereference"];
        description = "follow symbolic links";
      };
      fileMime = mk {
        args = ["--mime-type"];
        description = "print the MIME type";
      };
    };
  };

  findutils = mkSource {
    categories = ["core" "scripting"];
    description = "xargs (find is covered by fd)";
    discover = true;
    aliases = let
      mkFind = mkAlias "find";
      mkXargs = mkAlias "xargs";
    in {
      find0 = mkFind {
        args = ["-print0"];
        description = "find paths and separate results with NUL bytes";
      };
      xargs0 = mkXargs {
        args = ["-0"];
        description = "read NUL-separated arguments from standard input";
      };
      xargs0r = mkXargs {
        args = ["-0" "-r"];
        description = "read NUL-separated arguments and skip the command when there are none";
      };
      xargsn = mkXargs {
        args = ["-n"];
        description = "pass a caller-specified number of arguments per command";
      };
      xargsP = mkXargs {
        args = ["-P"];
        description = "run a caller-specified number of commands in parallel";
      };
      xargsr = mkXargs {
        args = ["-r"];
        description = "run the command only when standard input contains arguments";
      };
      xargsI = mkXargs {
        args = ["-I" "{}"];
        description = "replace each {} in the command with an input line";
      };
    };
  };

  fzf = mkSource {
    categories = ["files" "scripting"];
    description = "command-line fuzzy finder";
    aliases = let
      mk = mkAlias "fzf";
    in {
      fzf0 = mk {
        args = ["--read0" "--print0"];
        description = "read and write NUL-separated items";
      };
      fzf1 = mk {
        args = ["--select-1" "--exit-0"];
        description = "auto-select a single match and exit when nothing matches";
      };
      fzfe = mk {
        args = ["--exact"];
        description = "use exact matching instead of fuzzy matching";
      };
      fzfh = mk {
        args = ["--height" "40%"];
        description = "run inline using 40% of the terminal height";
      };
      fzfm = mk {
        args = ["--multi"];
        description = "allow selecting multiple items";
      };
      fzfp = mk {
        args = ["--preview"];
        description = "show a preview command for the highlighted item (caller supplies it)";
      };
      fzfq = mk {
        args = ["--query"];
        description = "start with a caller-specified query";
      };
      fzfr = mk {
        args = ["--reverse"];
        description = "show the prompt at the top with results below";
      };
    };
  };

  gawk = mkSource {
    categories = ["core" "scripting"];
    description = "GNU awk";
    discover = true;
    aliases = let
      mkAwk = mkAlias "awk";
      mkGawk = mkAlias "gawk";
    in {
      awkF = mkAwk {
        args = ["-F"];
        description = "set the input field separator";
      };
      awkFile = mkAwk {
        args = ["-f"];
        description = "run an awk program from a file";
      };
      awkInplace = mkGawk {
        args = ["-i" "inplace"];
        description = "edit files in place";
      };
      awkv = mkAwk {
        args = ["-v"];
        description = "assign a variable before running the program";
      };
    };
  };

  gh = mkSource {
    categories = ["shells" "scripting"];
    description = "GitHub CLI";
    aliases = let
      mk = mkAlias "gh";
    in {
      ghApi = mk {
        args = ["api"];
        description = "call a GitHub API endpoint";
      };
      ghAuthStatus = mk {
        args = ["auth" "status"];
        description = "show authentication status";
      };
      ghIssueCreate = mk {
        args = ["issue" "create"];
        description = "create an issue";
      };
      ghIssueList = mk {
        args = ["issue" "list"];
        description = "list issues";
      };
      ghPrCheckout = mk {
        args = ["pr" "checkout"];
        description = "check out a pull request locally";
      };
      ghPrCreate = mk {
        args = ["pr" "create"];
        description = "create a pull request";
      };
      ghPrList = mk {
        args = ["pr" "list"];
        description = "list pull requests";
      };
      ghPrStatus = mk {
        args = ["pr" "status"];
        description = "show the status of relevant pull requests";
      };
      ghPrView = mk {
        args = ["pr" "view"];
        description = "view a pull request";
      };
      ghRepoClone = mk {
        args = ["repo" "clone"];
        description = "clone a repository";
      };
      ghRepoView = mk {
        args = ["repo" "view"];
        description = "view a repository summary";
      };
      ghRepoViewWeb = mk {
        args = ["repo" "view" "--web"];
        description = "open a repository in the browser";
      };
      ghRunList = mk {
        args = ["run" "list"];
        description = "list recent workflow runs";
      };
      ghRunWatch = mk {
        args = ["run" "watch"];
        description = "watch a workflow run until it finishes";
      };
    };
  };

  git = mkSource {
    categories = ["shells" "scripting"];
    description = "distributed version control";
    aliases = let
      mk = mkAlias "git";
    in {
      gitAddAll = mk {
        args = ["add" "--all"];
        description = "stage all changes, including deletions and new files";
      };
      gitBranchCurrent = mk {
        args = ["branch" "--show-current"];
        description = "print the current branch name";
      };
      gitCfgFile = mk {
        args = ["config" "--file"];
        description = "read or write configuration in a caller-specified file";
      };
      gitCloneShallow = mk {
        args = ["clone" "--depth" "1"];
        description = "clone only the latest commit";
      };
      gitCommit = mk {
        args = ["commit" "--message"];
        description = "commit with a caller-specified message";
      };
      gitCommitAmend = mk {
        args = ["commit" "--amend"];
        description = "amend the previous commit";
      };
      gitCommitAmendNoEdit = mk {
        args = ["commit" "--amend" "--no-edit"];
        description = "amend the previous commit and keep its message";
      };
      gitDiffStaged = mk {
        args = ["diff" "--staged"];
        description = "show staged changes";
      };
      gitFetchPrune = mk {
        args = ["fetch" "--all" "--prune"];
        description = "fetch every remote and prune deleted branches";
      };
      gitLogGraph = mk {
        args = ["log" "--oneline" "--graph" "--decorate"];
        description = "show a compact commit graph";
      };
      gitPullRebase = mk {
        args = ["pull" "--rebase"];
        description = "pull and rebase local commits on top";
      };
      gitPushForce = mk {
        args = ["push" "--force-with-lease"];
        description = "force-push only if the remote has not changed unexpectedly";
      };
      gitRestoreStaged = mk {
        args = ["restore" "--staged"];
        description = "unstage files while keeping their changes";
      };
      gitStatus = mk {
        args = ["status" "--short" "--branch"];
        description = "show a compact status with branch information";
      };
      gitSwitchCreate = mk {
        args = ["switch" "--create"];
        description = "create and switch to a new branch";
      };
      gitTopLevel = mk {
        args = ["rev-parse" "--show-toplevel"];
        description = "print the repository root";
      };
    };
  };

  glib = mkSource {
    categories = ["desktop-cli" "scripting"];
    description = "gdbus, gio, and gsettings";
    discover = true; #? gdbus, gio, gsettings, ...
    exe = "gsettings";
    aliases = let
      mkGdbus = mkAlias "gdbus";
      mkGio = mkAlias "gio";
      mkGsettings = mkAlias "gsettings";
    in {
      gCall = mkGdbus {
        args = ["call"];
        description = "call a method on a D-Bus object";
      };
      gGet = mkGsettings {
        args = ["get"];
        description = "read a caller-specified GSettings key";
      };
      gGetDI = mkGsettings {
        args = ["get" "org.gnome.desktop.interface"];
        description = "read a GNOME desktop interface setting";
      };
      gIntrospect = mkGdbus {
        args = ["introspect" "--session" "--dest"];
        description = "introspect a session bus service (caller supplies destination and path)";
      };
      gListAll = mkGsettings {
        args = ["list-recursively"];
        description = "list every key and value in a schema";
      };
      gMonitor = mkGdbus {
        args = ["monitor" "--session" "--dest"];
        description = "watch signals from a session bus service";
      };
      gReset = mkGsettings {
        args = ["reset"];
        description = "reset a GSettings key to its default";
      };
      gSet = mkGsettings {
        args = ["set"];
        description = "set a caller-specified GSettings key";
      };
      gSetDI = mkGsettings {
        args = ["set" "org.gnome.desktop.interface"];
        description = "set a GNOME desktop interface setting";
      };
      gioInfo = mkGio {
        args = ["info"];
        description = "show file information and attributes";
      };
      gioOpen = mkGio {
        args = ["open"];
        description = "open a file or URI with its default application";
      };
      gioTrash = mkGio {
        args = ["trash"];
        description = "move files to the trash";
      };
    };
  };

  gnugrep = mkSource {
    categories = ["core" "scripting"];
    description = "GNU grep";
    discover = true;
    aliases = let
      mk = mkAlias "grep";
    in {
      grepc = mk {
        args = ["-c"];
        description = "count matching lines";
      };
      grepE = mk {
        args = ["-E"];
        description = "use extended regular expressions";
      };
      grepF = mk {
        args = ["-F"];
        description = "match fixed strings instead of regular expressions";
      };
      grepFxq = mk {
        args = ["-Fxq"];
        description = "quietly search for an exact fixed-string line";
      };
      grepi = mk {
        args = ["-i"];
        description = "search case-insensitively";
      };
      grepl = mk {
        args = ["-l"];
        description = "print only the names of files with matches";
      };
      grepn = mk {
        args = ["-n"];
        description = "show line numbers for matches";
      };
      grepo = mk {
        args = ["-o"];
        description = "print only the matching part of each line";
      };
      grepP = mk {
        args = ["-P"];
        description = "use Perl-compatible regular expressions";
      };
      grepq = mk {
        args = ["-q"];
        description = "search quietly and report success through the exit status";
      };
      grepr = mk {
        args = ["-r"];
        description = "search files recursively";
      };
      grepri = mk {
        args = ["-ri"];
        description = "search files recursively, ignoring case";
      };
      grepv = mk {
        args = ["-v"];
        description = "select non-matching lines";
      };
      grepw = mk {
        args = ["-w"];
        description = "match whole words only";
      };
    };
  };

  gnupatch = mkSource {
    categories = ["core" "scripting"];
    description = "apply diff patches";
    exe = "patch";
    aliases = let
      mk = mkAlias "patch";
    in {
      patchd = mk {
        args = ["-d"];
        description = "apply a patch from a caller-specified directory";
      };
      patchDry = mk {
        args = ["--dry-run"];
        description = "test whether a patch applies without changing files";
      };
      patchi = mk {
        args = ["-i"];
        description = "read the patch from a caller-specified file";
      };
      patchp0 = mk {
        args = ["-p0"];
        description = "apply a patch without stripping path components";
      };
      patchp1 = mk {
        args = ["-p1"];
        description = "apply a patch stripping one leading path component";
      };
      patchR = mk {
        args = ["-R"];
        description = "reverse a previously applied patch";
      };
    };
  };

  gnused = mkSource {
    categories = ["core" "scripting"];
    description = "GNU sed";
    discover = true;
    aliases = let
      mk = mkAlias "sed";
    in {
      sedE = mk {
        args = ["-E"];
        description = "use extended regular expressions";
      };
      sedi = mk {
        args = ["-i"];
        description = "edit files in place";
      };
      sediBak = mk {
        args = ["-i.bak"];
        description = "edit files in place and keep .bak backups";
      };
      sediE = mk {
        args = ["-i" "-E"];
        description = "edit files in place using extended regular expressions";
      };
      sedn = mk {
        args = ["-n"];
        description = "print only explicitly selected lines";
      };
      sednE = mk {
        args = ["-nE"];
        description = "print only selected lines using extended regular expressions";
      };
      sedz = mk {
        args = ["-z"];
        description = "treat NUL-separated records as lines";
      };
    };
  };

  gum = mkSource {
    categories = ["shells" "scripting"];
    description = "glamorous shell script helpers";
    aliases = let
      mk = mkAlias "gum";
    in {
      gumChoose = mk {
        args = ["choose"];
        description = "pick one option from a list";
      };
      gumChooseMulti = mk {
        args = ["choose" "--no-limit"];
        description = "pick any number of options from a list";
      };
      gumConfirm = mk {
        args = ["confirm"];
        description = "ask a yes/no question and report the answer through the exit status";
      };
      gumFile = mk {
        args = ["file"];
        description = "pick a file from a directory";
      };
      gumFilter = mk {
        args = ["filter"];
        description = "fuzzy-filter lines from standard input";
      };
      gumInput = mk {
        args = ["input"];
        description = "prompt for a single line of text";
      };
      gumLog = mk {
        args = ["log"];
        description = "print a structured log message";
      };
      gumPager = mk {
        args = ["pager"];
        description = "scroll through text in a pager";
      };
      gumSpin = mk {
        args = ["spin" "--title"];
        description = "show a spinner while a command runs (caller supplies the title, then -- and the command)";
      };
      gumStyle = mk {
        args = ["style"];
        description = "apply colors, borders, and spacing to text";
      };
      gumWrite = mk {
        args = ["write"];
        description = "prompt for multi-line text";
      };
    };
  };

  hyprpaper = mkSource {
    categories = ["desktop-ui"];
    description = "wallpaper daemon for Hyprland";
    aliases.hyprpaperConfig = mkAlias "hyprpaper" {
      args = ["--config"];
      description = "start with a caller-specified configuration file";
    };
  };

  iproute2 = mkSource {
    categories = ["networking" "scripting"];
    description = "ip, ss, bridge, and related networking tools";
    discover = true; #? ip, ss, bridge, ...
    exe = "ip";
    aliases = let
      mkIp = mkAlias "ip";
      mkSs = mkAlias "ss";
    in {
      ip4 = mkIp {
        args = ["-4"];
        description = "limit output to IPv4";
      };
      ip6 = mkIp {
        args = ["-6"];
        description = "limit output to IPv6";
      };
      ipBrAddr = mkIp {
        args = ["-brief" "address"];
        description = "show a compact table of interface addresses";
      };
      ipBrLink = mkIp {
        args = ["-brief" "link"];
        description = "show a compact table of interface link states";
      };
      ipJson = mkIp {
        args = ["-json"];
        description = "output JSON";
      };
      ipNeigh = mkIp {
        args = ["neighbour" "show"];
        description = "show the neighbour (ARP/NDP) table";
      };
      ipRoute = mkIp {
        args = ["route" "show"];
        description = "show the routing table";
      };
      ssListen = mkSs {
        args = ["-tulpn"];
        description = "show listening TCP and UDP sockets with processes and numeric ports";
      };
      ssSummary = mkSs {
        args = ["--summary"];
        description = "show socket statistics";
      };
    };
  };

  jaq = mkSource {
    categories = ["text" "scripting"];
    description = "jq-compatible JSON processor (Rust)";
    aliases = let
      mk = mkAlias "jaq";
    in {
      jaqc = mk {
        args = ["-c"];
        description = "output compact JSON";
      };
      jaqf = mk {
        args = ["--from-file"];
        description = "read the filter from a file";
      };
      jaqn = mk {
        args = ["-n"];
        description = "run without reading input";
      };
      jaqr = mk {
        args = ["-r"];
        description = "output strings without JSON quotes";
      };
      jaqna = mk {
        args = ["-n" "--arg"];
        description = "run without input and bind a caller-specified string argument";
      };
      jaqRawInput = mk {
        args = ["-R"];
        description = "read each input line as a string";
      };
      jaqRr = mk {
        args = ["-Rr"];
        description = "read raw input lines and output raw strings";
      };
      jaqs = mk {
        args = ["-s"];
        description = "read all inputs into a single array";
      };
    };
  };

  jq = mkSource {
    categories = ["text" "scripting"];
    description = "command-line JSON processor";
    aliases = let
      mk = mkAlias "jq";
    in {
      jqc = mk {
        args = ["-c"];
        description = "output compact JSON";
      };
      jqe = mk {
        args = ["-e"];
        description = "set the exit status from the last output value";
      };
      jqf = mk {
        args = ["--from-file"];
        description = "read the filter from a file";
      };
      jqj = mk {
        args = ["-j"];
        description = "output raw strings without trailing newlines";
      };
      jqn = mk {
        args = ["-n"];
        description = "run without reading input";
      };
      jqna = mk {
        args = ["-n" "--arg"];
        description = "run without input and bind a caller-specified string argument";
      };
      jqr = mk {
        args = ["-r"];
        description = "output strings without JSON quotes";
      };
      jqRawInput = mk {
        args = ["-R"];
        description = "read each input line as a string";
      };
      jqRr = mk {
        args = ["-Rr"];
        description = "read raw input lines and output raw strings";
      };
      jqRs = mk {
        args = ["-Rs"];
        description = "read all input as a single raw string";
      };
      jqs = mk {
        args = ["-s"];
        description = "read all inputs into a single array";
      };
      jqSortKeys = mk {
        args = ["--sort-keys"];
        description = "output object keys in sorted order";
      };
    };
  };

  libnotify = mkSource {
    categories = ["desktop-cli" "scripting"];
    description = "desktop notifications";
    exe = "notify-send";
    aliases = let
      mk = mkAlias "notify-send";
    in {
      notifyApp = mk {
        args = ["--app-name"];
        description = "send a notification under a caller-specified application name";
      };
      notifyCritical = mk {
        args = ["--urgency=critical"];
        description = "send a critical-urgency notification";
      };
      notifyExpire = mk {
        args = ["--expire-time"];
        description = "send a notification that expires after a caller-specified time in milliseconds";
      };
      notifyIcon = mk {
        args = ["--icon"];
        description = "send a notification with a caller-specified icon";
      };
      notifyTransient = mk {
        args = ["--transient"];
        description = "send a notification that is not kept in notification history";
      };
    };
  };

  moreutils = mkSource {
    categories = ["core" "scripting"];
    description = "additional Unix tools, including sponge and parallel";
    discover = true;
    aliases = let
      mkChronic = mkAlias "chronic";
      mkIfne = mkAlias "ifne";
      mkParallel = mkAlias "parallel";
      mkSponge = mkAlias "sponge";
      mkTs = mkAlias "ts";
    in {
      chronicE = mkChronic {
        args = ["-e"];
        description = "treat any standard error output as a failure and show the output";
      };
      chronicv = mkChronic {
        args = ["-v"];
        description = "run quietly unless the command fails, with verbose failure output";
      };
      ifnen = mkIfne {
        args = ["-n"];
        description = "run the command only when standard input is empty";
      };
      parallelj = mkParallel {
        args = ["-j"];
        description = "run a caller-specified number of jobs at once";
      };
      spongea = mkSponge {
        args = ["-a"];
        description = "append buffered standard input to a file";
      };
      tsElapsed = mkTs {
        args = ["-s"];
        description = "prefix each line with the time elapsed since start";
      };
      tsIncremental = mkTs {
        args = ["-i"];
        description = "prefix each line with the time since the previous line";
      };
    };
  };

  nemo = mkSource {
    categories = ["desktop-ui"];
    description = "Nemo file manager with extensions";
    target = (import ../../applications/data/explorers.nix {}).nemo.names.package;
    exe = "nemo";
  };

  ouch = mkSource {
    categories = ["archives" "scripting"];
    description = "unified archive compressor and decompressor for tar, zip, 7z, gz, xz, zst, and more";
    aliases = let
      mk = mkAlias "ouch";
    in {
      lsar = mk {
        args = ["list"];
        description = "list archive contents";
      };
      lsarTree = mk {
        args = ["list" "--tree"];
        description = "list archive contents as a tree";
      };
      pack = mk {
        args = ["compress"];
        description = "compress files into an archive";
      };
      packYes = mk {
        args = ["compress" "--yes"];
        description = "compress files, overwriting existing output without asking";
      };
      unpack = mk {
        args = ["decompress"];
        description = "decompress an archive";
      };
      unpackTo = mk {
        args = ["decompress" "--dir"];
        description = "decompress into a caller-specified directory";
      };
      unpackYes = mk {
        args = ["decompress" "--yes"];
        description = "decompress, overwriting existing files without asking";
      };
    };
  };

  procps = mkSource {
    categories = ["system" "scripting"];
    description = "pkill, pgrep, ps, top, and related process tools";
    discover = true; #? pkill, pgrep, ps, top, ...
    exe = "pkill";
    aliases = let
      mkFree = mkAlias "free";
      mkPgrep = mkAlias "pgrep";
      mkPidof = mkAlias "pidof";
      mkPkill = mkAlias "pkill";
      mkPs = mkAlias "ps";
      mkTop = mkAlias "top";
      mkUptime = mkAlias "uptime";
      mkWatch = mkAlias "watch";
    in {
      freeh = mkFree {
        args = ["-h"];
        description = "show memory usage in human-readable sizes";
      };
      pgrepf = mkPgrep {
        args = ["-f"];
        description = "find processes by matching the full command line";
      };
      pgrepa = mkPgrep {
        args = ["-a"];
        description = "show matching process IDs with their full command lines";
      };
      pgrepc = mkPgrep {
        args = ["-c"];
        description = "count matching processes";
      };
      pgrepl = mkPgrep {
        args = ["-l"];
        description = "show matching process IDs with process names";
      };
      pgrepu = mkPgrep {
        args = ["-u"];
        description = "find processes owned by a caller-specified user";
      };
      pgrepx = mkPgrep {
        args = ["-x"];
        description = "find processes matching the exact name";
      };
      pidofs = mkPidof {
        args = ["-s"];
        description = "print a single matching process ID";
      };
      pkillf = mkPkill {
        args = ["-f"];
        description = "signal processes whose full command lines match";
      };
      pkillHUP = mkPkill {
        args = ["-HUP"];
        description = "send SIGHUP to matching processes";
      };
      pkillHUPx = mkPkill {
        args = ["-HUP" "-x"];
        description = "send SIGHUP to processes matching the exact name";
      };
      pkill9 = mkPkill {
        args = ["-9"];
        description = "force-kill matching processes";
      };
      pkill9x = mkPkill {
        args = ["-9" "-x"];
        description = "force-kill processes matching the exact name";
      };
      pkillUSR1 = mkPkill {
        args = ["-USR1"];
        description = "send SIGUSR1 to matching processes";
      };
      pkillUSR1x = mkPkill {
        args = ["-USR1" "-x"];
        description = "send SIGUSR1 to processes matching the exact name";
      };
      pkillUSR2 = mkPkill {
        args = ["-USR2"];
        description = "send SIGUSR2 to matching processes";
      };
      pkillUSR2x = mkPkill {
        args = ["-USR2" "-x"];
        description = "send SIGUSR2 to processes matching the exact name";
      };
      pkillx = mkPkill {
        args = ["-x"];
        description = "signal processes matching the exact name";
      };
      psaux = mkPs {
        args = ["aux"];
        description = "list all processes with user and resource columns";
      };
      psCpu = mkPs {
        args = ["aux" "--sort=-%cpu"];
        description = "list processes sorted by CPU usage, highest first";
      };
      psef = mkPs {
        args = ["-ef"];
        description = "list all processes in full format";
      };
      psMem = mkPs {
        args = ["aux" "--sort=-%mem"];
        description = "list processes sorted by memory usage, highest first";
      };
      topBatch = mkTop {
        args = ["-b" "-n" "1"];
        description = "print a single non-interactive snapshot of top";
      };
      uptimePretty = mkUptime {
        args = ["--pretty"];
        description = "show uptime in a human-readable form";
      };
      watchd = mkWatch {
        args = ["--differences"];
        description = "repeat a command and highlight changes between runs";
      };
      watchn = mkWatch {
        args = ["-n"];
        description = "repeat a command at a caller-specified interval in seconds";
      };
    };
  };

  quickshell = mkSource {
    categories = ["desktop-ui"];
    description = "QtQuick-based desktop shell";
    input = "quickshell";
    aliases = let
      mk = mkAlias "quickshell";
    in {
      quickshellConfig = mk {
        args = ["--config"];
        description = "start a named configuration (caller supplies it)";
      };
      quickshellKill = mk {
        args = ["kill"];
        description = "stop a running quickshell instance";
      };
      quickshellList = mk {
        args = ["list"];
        description = "list running quickshell instances";
      };
      quickshellPath = mk {
        args = ["--path"];
        description = "start from a caller-specified configuration path";
      };
    };
  };

  ripgrep = mkSource {
    categories = ["text" "scripting"];
    description = "fast recursive grep (rg)";
    aliases = let
      mk = mkAlias "rg";
    in {
      rgi = mk {
        args = ["-i"];
        description = "search case-insensitively";
      };
      rg0 = mk {
        args = ["--null"];
        description = "separate matching paths with NUL bytes";
      };
      rgc = mk {
        args = ["--count"];
        description = "count matching lines per file";
      };
      rgContext = mk {
        args = ["--context"];
        description = "show a caller-specified number of context lines around matches";
      };
      rgF = mk {
        args = ["--fixed-strings"];
        description = "match literal strings instead of regular expressions";
      };
      rgFiles = mk {
        args = ["--files"];
        description = "list files that would be searched";
      };
      rgFilesWithout = mk {
        args = ["--files-without-match"];
        description = "list files that contain no matches";
      };
      rgFxq = mk {
        args = ["-Fxq"];
        description = "quietly search for an exact fixed-string line";
      };
      rgg = mk {
        args = ["--glob"];
        description = "include or exclude paths with a caller-specified glob";
      };
      rgh = mk {
        args = ["--hidden" "--no-ignore"];
        description = "search including hidden and ignored paths";
      };
      rgj = mk {
        args = ["--json"];
        description = "output matches as JSON lines";
      };
      rgl = mk {
        args = ["--files-with-matches"];
        description = "print only the names of files with matches";
      };
      rgm = mk {
        args = ["--multiline"];
        description = "allow matches to span multiple lines";
      };
      rgo = mk {
        args = ["--only-matching"];
        description = "print only the matching part of each line";
      };
      rgq = mk {
        args = ["-q"];
        description = "search quietly and report success through the exit status";
      };
      rgt = mk {
        args = ["--type"];
        description = "search only a caller-specified file type";
      };
      rgTypeNot = mk {
        args = ["--type-not"];
        description = "skip a caller-specified file type";
      };
      rgv = mk {
        args = ["--invert-match"];
        description = "show lines that do not match";
      };
      rgw = mk {
        args = ["--word-regexp"];
        description = "match whole words only";
      };
    };
  };

  sd = mkSource {
    categories = ["text" "scripting"];
    description = "intuitive sed alternative";
    aliases = let
      mk = mkAlias "sd";
    in {
      sdf = mk {
        args = ["--flags"];
        description = "set regex flags such as i or m (caller supplies them)";
      };
      sdp = mk {
        args = ["--preview"];
        description = "preview replacements without writing files";
      };
      sds = mk {
        args = ["--string-mode"];
        description = "treat the pattern as a literal string";
      };
    };
  };

  swaybg = mkSource {
    categories = [["desktop-ui"]];
    description = "wallpaper utility for Sway";
    aliases = let
      mk = mkAlias "swaybg";
    in {
      swaybgColor = mk {
        args = ["--color"];
        description = "set a solid background color (caller supplies it)";
      };
      swaybgFill = mk {
        args = ["--mode" "fill" "--image"];
        description = "set an image wallpaper scaled to fill the output (caller supplies the image)";
      };
      swaybgImage = mk {
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
    aliases = let
      mkJournalctl = mkAlias "journalctl";
      mkSystemctl = mkAlias "systemctl";
      mkSystemdAnalyze = mkAlias "systemd-analyze";
      mkSystemdRun = mkAlias "systemd-run";
    in {
      journalctlBoot = mkJournalctl {
        args = ["--boot"];
        description = "show journal entries from the current boot";
      };
      journalctlErr = mkJournalctl {
        args = ["--boot" "--priority=err"];
        description = "show errors and worse from the current boot";
      };
      journalctlFollow = mkJournalctl {
        args = ["--follow"];
        description = "follow new journal entries as they arrive";
      };
      journalctlSince = mkJournalctl {
        args = ["--since"];
        description = "show journal entries since a caller-specified time";
      };
      journalctlUnit = mkJournalctl {
        args = ["--unit"];
        description = "show journal entries for a caller-specified unit";
      };
      journalctlUser = mkJournalctl {
        args = ["--user"];
        description = "show journal entries for the current user";
      };
      journalctlUserUnit = mkJournalctl {
        args = ["--user" "--unit"];
        description = "show journal entries for a caller-specified user unit";
      };
      systemctlCat = mkSystemctl {
        args = ["cat"];
        description = "show a unit file and its drop-ins";
      };
      systemctlDaemonReload = mkSystemctl {
        args = ["daemon-reload"];
        description = "reload systemd manager configuration";
      };
      systemctlDisableNow = mkSystemctl {
        args = ["disable" "--now"];
        description = "disable a unit and stop it immediately";
      };
      systemctlEnableNow = mkSystemctl {
        args = ["enable" "--now"];
        description = "enable a unit and start it immediately";
      };
      systemctlFailed = mkSystemctl {
        args = ["--failed"];
        description = "list failed units";
      };
      systemctlRestart = mkSystemctl {
        args = ["restart"];
        description = "restart a unit";
      };
      systemctlStart = mkSystemctl {
        args = ["start"];
        description = "start a unit";
      };
      systemctlStatus = mkSystemctl {
        args = ["status"];
        description = "show a unit's status";
      };
      systemctlStop = mkSystemctl {
        args = ["stop"];
        description = "stop a unit";
      };
      systemctlUser = mkSystemctl {
        args = ["--user"];
        description = "manage the current user's systemd services";
      };
      systemctlUserR = mkSystemctl {
        args = ["--user" "reload"];
        description = "reload a current-user systemd service";
      };
      systemctlUserDaemonReload = mkSystemctl {
        args = ["--user" "daemon-reload"];
        description = "reload the current user's systemd manager configuration";
      };
      systemctlUserDisableNow = mkSystemctl {
        args = ["--user" "disable" "--now"];
        description = "disable a current-user unit and stop it immediately";
      };
      systemctlUserEnableNow = mkSystemctl {
        args = ["--user" "enable" "--now"];
        description = "enable a current-user unit and start it immediately";
      };
      systemctlUserFailed = mkSystemctl {
        args = ["--user" "--failed"];
        description = "list failed current-user units";
      };
      systemctlUserRestart = mkSystemctl {
        args = ["--user" "restart"];
        description = "restart a current-user unit";
      };
      systemctlUserStart = mkSystemctl {
        args = ["--user" "start"];
        description = "start a current-user unit";
      };
      systemctlUserStatus = mkSystemctl {
        args = ["--user" "status"];
        description = "show a current-user unit's status";
      };
      systemctlUserStop = mkSystemctl {
        args = ["--user" "stop"];
        description = "stop a current-user unit";
      };
      systemdAnalyzeBlame = mkSystemdAnalyze {
        args = ["blame"];
        description = "list units by startup time";
      };
      systemdAnalyzeVerify = mkSystemdAnalyze {
        args = ["verify"];
        description = "check unit files for errors";
      };
      systemdRunUser = mkSystemdRun {
        args = ["--user"];
        description = "run a command as a transient current-user unit";
      };
    };
  };

  tree = mkSource {
    categories = ["core" "scripting"];
    description = "list directory contents as a tree";
    aliases = let
      mk = mkAlias "tree";
    in {
      treea = mk {
        args = ["-a"];
        description = "include hidden files";
      };
      treed = mk {
        args = ["-d"];
        description = "list directories only";
      };
      treef = mk {
        args = ["-f"];
        description = "print the full path prefix for each entry";
      };
      treeh = mk {
        args = ["-h"];
        description = "show human-readable sizes";
      };
      treeI = mk {
        args = ["-I"];
        description = "exclude entries matching a caller-specified pattern";
      };
      treeJ = mk {
        args = ["-J"];
        description = "output the tree as JSON";
      };
      treeL = mk {
        args = ["-L"];
        description = "limit the display depth";
      };
      treep = mk {
        args = ["--prune"];
        description = "omit empty directories";
      };
    };
  };

  util-linux = mkSource {
    categories = ["system" "scripting"];
    description = "mount, lsblk, flock, logger, and related system utilities";
    discover = true; #? mount, lsblk, flock, logger, ...
    exe = "mount";
    aliases = let
      mkColumn = mkAlias "column";
      mkDmesg = mkAlias "dmesg";
      mkFindmnt = mkAlias "findmnt";
      mkFlock = mkAlias "flock";
      mkHexdump = mkAlias "hexdump";
      mkLogger = mkAlias "logger";
      mkLsblk = mkAlias "lsblk";
      mkLscpu = mkAlias "lscpu";
      mkMount = mkAlias "mount";
      mkMountpoint = mkAlias "mountpoint";
      mkUmount = mkAlias "umount";
    in {
      columnt = mkColumn {
        args = ["--table"];
        description = "align input into table columns";
      };
      columnts = mkColumn {
        args = ["--table" "--separator"];
        description = "align input into a table using a caller-specified separator";
      };
      dmesgErr = mkDmesg {
        args = ["--level=err,warn"];
        description = "show kernel errors and warnings";
      };
      dmesgH = mkDmesg {
        args = ["--human"];
        description = "show kernel messages with readable timestamps and paging";
      };
      dmesgw = mkDmesg {
        args = ["--follow"];
        description = "follow new kernel messages";
      };
      findmntJ = mkFindmnt {
        args = ["--json"];
        description = "show mounts as JSON";
      };
      findmntT = mkFindmnt {
        args = ["--types"];
        description = "show mounts of a caller-specified filesystem type";
      };
      flockn = mkFlock {
        args = ["--nonblock"];
        description = "fail immediately if the lock is already held";
      };
      flockw = mkFlock {
        args = ["--wait"];
        description = "wait a caller-specified number of seconds for the lock";
      };
      hexdumpC = mkHexdump {
        args = ["-C"];
        description = "show canonical hex and ASCII output";
      };
      loggerp = mkLogger {
        args = ["--priority"];
        description = "write a message with a caller-specified priority";
      };
      loggerS = mkLogger {
        args = ["--stderr"];
        description = "write a message to the journal and also to standard error";
      };
      loggerT = mkLogger {
        args = ["-t"];
        description = "write a message to the journal with a caller-specified tag";
      };
      lsblka = mkLsblk {
        args = ["--all"];
        description = "list all block devices, including empty ones";
      };
      lsblkf = mkLsblk {
        args = ["--fs"];
        description = "list block devices with filesystem information";
      };
      lsblkJ = mkLsblk {
        args = ["--json"];
        description = "list block devices as JSON";
      };
      lsblkp = mkLsblk {
        args = ["--paths"];
        description = "list block devices with full device paths";
      };
      lscpuJ = mkLscpu {
        args = ["--json"];
        description = "show CPU information as JSON";
      };
      mountBind = mkMount {
        args = ["--bind"];
        description = "bind-mount a directory at another location";
      };
      mountpointq = mkMountpoint {
        args = ["--quiet"];
        description = "check whether a path is a mount point through the exit status";
      };
      mountt = mkMount {
        args = ["--types"];
        description = "mount using a caller-specified filesystem type";
      };
      umountl = mkUmount {
        args = ["--lazy"];
        description = "detach a filesystem now and clean up when it is no longer busy";
      };
      umountR = mkUmount {
        args = ["--recursive"];
        description = "unmount a filesystem and everything mounted beneath it";
      };
    };
  };

  variety = mkSource {
    categories = ["desktop-ui"];
    description = "wallpaper changer with scheduling and effects";
    aliases = let
      mk = mkAlias "variety";
    in {
      varietyFavorite = mk {
        args = ["--favorite"];
        description = "move the current wallpaper to favorites";
      };
      varietyNext = mk {
        args = ["--next"];
        description = "switch to the next wallpaper";
      };
      varietyPreferences = mk {
        args = ["--preferences"];
        description = "open the preferences window";
      };
      varietyPrevious = mk {
        args = ["--previous"];
        description = "switch to the previous wallpaper";
      };
      varietyQuit = mk {
        args = ["--quit"];
        description = "quit the running instance";
      };
      varietyTogglePause = mk {
        args = ["--toggle-pause"];
        description = "pause or resume wallpaper changes";
      };
      varietyTrash = mk {
        args = ["--trash"];
        description = "move the current wallpaper to the trash";
      };
    };
  };

  vscode-fhs = mkSource {
    categories = ["editors"];
    description = "VS Code (FHS environment)";
    aliases = let
      mk = mkAlias "code";
    in {
      codeAdd = mk {
        args = ["--add"];
        description = "add a folder to the last active window";
      };
      codeDiff = mk {
        args = ["--diff"];
        description = "compare two files";
      };
      codeExtInstall = mk {
        args = ["--install-extension"];
        description = "install an extension (caller supplies its identifier)";
      };
      codeExtList = mk {
        args = ["--list-extensions"];
        description = "list installed extensions";
      };
      codeGoto = mk {
        args = ["--goto"];
        description = "open a file at a caller-specified line and column (file:line:column)";
      };
      codeNew = mk {
        args = ["--new-window"];
        description = "open in a new window";
      };
      codeReuse = mk {
        args = ["--reuse-window"];
        description = "open in the last active window";
      };
      codeSafe = mk {
        args = ["--disable-extensions"];
        description = "start with all extensions disabled";
      };
      codeWait = mk {
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
    aliases = let
      mk = mkAlias "code-insiders";
    in {
      codeInsidersDiff = mk {
        args = ["--diff"];
        description = "compare two files";
      };
      codeInsidersExtInstall = mk {
        args = ["--install-extension"];
        description = "install an extension (caller supplies its identifier)";
      };
      codeInsidersExtList = mk {
        args = ["--list-extensions"];
        description = "list installed extensions";
      };
      codeInsidersGoto = mk {
        args = ["--goto"];
        description = "open a file at a caller-specified line and column (file:line:column)";
      };
      codeInsidersNew = mk {
        args = ["--new-window"];
        description = "open in a new window";
      };
      codeInsidersWait = mk {
        args = ["--wait"];
        description = "wait for the file to be closed before returning";
      };
    };
  };

  wl-clipboard = mkSource {
    categories = ["desktop-cli" "scripting"];
    description = "wl-copy, wl-paste, and related Wayland clipboard tools";
    discover = true; #? wl-copy, wl-paste
    exe = "wl-copy";
    aliases = let
      mkWlCopy = mkAlias "wl-copy";
      mkWlPaste = mkAlias "wl-paste";
    in {
      wlCopyClear = mkWlCopy {
        args = ["--clear"];
        description = "clear the clipboard";
      };
      wlCopyPrimary = mkWlCopy {
        args = ["--primary"];
        description = "copy to the primary selection";
      };
      wlCopyTrim = mkWlCopy {
        args = ["--trim-newline"];
        description = "copy without the trailing newline";
      };
      wlCopyType = mkWlCopy {
        args = ["--type"];
        description = "copy using a caller-specified MIME type";
      };
      wlPasteList = mkWlPaste {
        args = ["--list-types"];
        description = "list the MIME types available on the clipboard";
      };
      wlPasteNoNewline = mkWlPaste {
        args = ["--no-newline"];
        description = "paste without adding a trailing newline";
      };
      wlPastePrimary = mkWlPaste {
        args = ["--primary"];
        description = "paste from the primary selection";
      };
      wlPasteType = mkWlPaste {
        args = ["--type"];
        description = "paste a caller-specified MIME type";
      };
      wlPasteWatch = mkWlPaste {
        args = ["--watch"];
        description = "run a command each time the clipboard changes";
      };
    };
  };

  xdg-utils = mkSource {
    categories = ["desktop-cli" "scripting"];
    description = "xdg-open, xdg-mime, and related desktop integration tools";
    discover = true; #? xdg-open, xdg-mime, ...
    exe = "xdg-open";
    aliases = let
      mkXdgMime = mkAlias "xdg-mime";
      mkXdgSettings = mkAlias "xdg-settings";
    in {
      xdgBrowserGet = mkXdgSettings {
        args = ["get" "default-web-browser"];
        description = "show the default web browser";
      };
      xdgBrowserSet = mkXdgSettings {
        args = ["set" "default-web-browser"];
        description = "set the default web browser (caller supplies the .desktop file)";
      };
      xdgMimeDefault = mkXdgMime {
        args = ["default"];
        description = "set the default application for a MIME type (caller supplies both)";
      };
      xdgMimeQueryDefault = mkXdgMime {
        args = ["query" "default"];
        description = "show the default application for a MIME type";
      };
      xdgMimeQueryFiletype = mkXdgMime {
        args = ["query" "filetype"];
        description = "show the MIME type of a file";
      };
      xdgSettingsGet = mkXdgSettings {
        args = ["get"];
        description = "read a desktop setting";
      };
      xdgSettingsSet = mkXdgSettings {
        args = ["set"];
        description = "change a desktop setting";
      };
    };
  };

  yq-go = mkSource {
    categories = ["text" "scripting"];
    description = "portable YAML, JSON, and XML processor (Go)";
    aliases = let
      mk = mkAlias "yq";
    in {
      yqe = mk {
        args = ["eval"];
        description = "evaluate an expression against each file separately";
      };
      yqea = mk {
        args = ["eval-all"];
        description = "evaluate an expression against all files together";
      };
      yqi = mk {
        args = ["--inplace"];
        description = "edit files in place";
      };
      yqJsonToYaml = mk {
        args = ["--input-format" "json" "--output-format" "yaml"];
        description = "convert JSON to YAML";
      };
      yqMerge = mk {
        args = ["eval-all" "select(fileIndex == 0) * select(fileIndex == 1)"];
        description = "deep-merge two files, with the second taking precedence";
      };
      yqn = mk {
        args = ["--null-input"];
        description = "run without reading input";
      };
      yqP = mk {
        args = ["--prettyPrint"];
        description = "pretty-print the output";
      };
      yqToJson = mk {
        args = ["--output-format" "json"];
        description = "convert YAML to JSON";
      };
    };
  };
}
