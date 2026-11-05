{
  mkAlias,
  mkAliasFamily,
  mergeDisjoint,
  mkSource,
  readFile,
  mkPath,
  ...
}: {
  git = let
    mkHelper = name: description:
      mkAlias "git" {
        args = [
          "-c"
          "alias.project-${name}=!helper() {\n${readFile (
            mkPath {
              root = ["lib" "sh"];
              stem = ["project" "git" name];
            }
          )}\n}; helper"
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
}
