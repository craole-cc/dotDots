{
  mkAliasFamily,
  mkSource,
  ...
}: {
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

  rust-script = mkSource {
    categories = ["scripting"];
    description = "run Rust files and expressions as scripts";
    target = "rust-script";
    exe = "rust-script";
  };
}
