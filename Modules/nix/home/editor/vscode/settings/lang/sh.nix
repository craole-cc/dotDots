{
  context,
  mkEnable,
  requires,
  ...
}: let
  lang = "shellscript";
  condition = requires [lang "bash" "sh" "shell"];
  enable = condition;
  options.${lang}.enable = mkEnable {inherit context condition;};

  defaultFormatter = "mkhl.shfmt";
  editor = {inherit defaultFormatter;};
  extensions = [
    defaultFormatter
    "mads-hartmann.bash-ide-vscode"
    "timonwong.shellcheck"
    "vix.lint-runner"
  ];

  settings = {
    "[${lang}]" = {inherit editor;};
    "[dotenv]" = {inherit editor;};

    bashIde = {
      #~@ Bash IDE
      # Glob patterns excluded from background file discovery. Open files and sourced files can still be analyzed on demand.
      backgroundAnalysisIgnore = [
        "**/node_modules/**"
        "**/.git/**"
      ];

      # Maximum number of files to analyse in the background. Set to 0 to disable background analysis.
      backgroundAnalysisMaxFiles = 500;

      # Enable diagnostics for source errors. Ignored if includeAllWorkspaceSymbols is true.
      enableSourceErrorDiagnostics = false;

      # Configure explainshell server endpoint in order to get hover documentation on flags and options.
      explainshellEndpoint = "http://localhost:5000";

      # Glob pattern for finding and parsing shell script files in the workspace. Used by the background analysis features across files.
      globPattern = "**/*@(.sh|.inc|.bash|.command)";

      # Controls how symbols (e.g. variables and functions) are included and used for completion, documentation, and renaming. If false (default and recommended), then we only include symbols from sourced files (i.e. using non dynamic statements like 'source file.sh' or '. file.sh' or following ShellCheck directives). If true, then all symbols from the workspace are included.
      includeAllWorkspaceSymbols = false;

      # Controls the log level of the language server.
      logLevel = "info";

      # Additional ShellCheck arguments. Note that we already add the following arguments: --shell, --format, and --external-sources (if shellcheckExternalSources is true).
      shellcheckArguments = "";

      # Controls whether ShellCheck is invoked with --external-sources. When enabled (default), ShellCheck follows source directives to lint referenced files. On projects with many cross-sourcing scripts this can cause unbounded memory growth. Set to false to disable.
      shellcheckExternalSources = true;

      # Controls the executable used for ShellCheck linting information. An empty string will disable linting.
      shellcheckPath = "shellcheck";

      shfmt = {
        # Additional Shfmt arguments. Note that common arguments can be configured via the other settings.
        additionalArguments = [];

        # Allow boolean operators (like && and ||) to start a line.
        binaryNextLine = false;

        # Indent patterns in case statements.
        caseIndent = false;

        # Place function opening braces on a separate line.
        funcNextLine = false;

        # Ignore shfmt config options in .editorconfig (always use language server config)
        ignoreEditorconfig = false;

        # **([Deprecated](https://github.com/mvdan/sh/issues/658))** Keep column alignment padding.
        keepPadding = false;

        # Language dialect to use when parsing (bash/posix/mksh/bats).
        languageDialect = "auto";

        # Controls the executable used for Shfmt formatting. An empty string will disable formatting.
        path = "shfmt";

        # Simplify code before formatting.
        simplifyCode = false;

        # Follow redirection operators with a space.
        spaceRedirects = false;
      };
    };

    #~@ dotEnv
    dotenv = {
      enableAutocloaking = false;
    };

    shellcheck = {
      #~@ ShellCheck
      # Custom arguments to pass to ShellCheck. Always prefer to use a `.shellcheckrc` file instead of this setting. When `shellcheck.runtime` is `wasm`, as it always is in VS Code for the Web, paths on your machine in these arguments do not resolve.
      customArgs = [];

      # Whether ShellCheck is enabled or not.
      enable = true;

      # Whether to enable the _Quick Fix_ feature or not.
      enableQuickFix = true;

      # Exclude certain error codes. For example, to exclude [SC1017](https://shellcheck.net/wiki/SC1017), enter _1017_. Enumerated error codes can be found [in this gist](https://gist.github.com/nicerobot/53cee11ee0abbdc997661e65b348f375). Always prefer to use a `.shellcheckrc` file instead of this setting.
      exclude = [];

      # Matching file schemes are being ignored by shellcheck. The default also covers the virtual documents of the GitHub Pull Requests extension.
      ignoreFileSchemes = [
        "git"
        "gitfs"
        "output"
        "review"
        "pr"
        "githubpr"
        "gitpr"
        "githubcommit"
      ];

      # The trace level the extension logs at, defaults to 'info'.
      logLevel = "info";

      # **Experimental:** Show a formatted ShellCheck hover with severity and rule documentation. VS Code also displays the original diagnostic; the Problems view is unchanged. [Read the documentation](https://github.com/vscode-shellcheck/vscode-shellcheck#shellcheckmarkdowndiagnostics).
      markdownDiagnostics = false;

      # The most `shellcheck` runs at once. `0` uses the runtime's default: no limit for `native`, 2 for `wasm`. Lints beyond it wait for a running one to finish. Each `wasm` run takes a worker of its own, which can use over 100 MiB of memory.
      maxConcurrentRuns = 0;

      # What triggers a lint: typing, saving, or only the Lint Current Document command.
      run = "onType";

      # **Experimental.** Which ShellCheck runtime to use. VS Code for the Web always uses `wasm` and ignores this setting.
      #
      # - `auto` — `native` on desktop and `wasm` in VS Code for the Web. This is the default.
      # - `native` — run the bundled or user-provided `shellcheck` executable. This is the only supported runtime on desktop.
      # - `wasm` — run a bundled WebAssembly (WASI) build of ShellCheck inside the editor. No executable is required and it works on every platform and in virtual workspaces, but linting is currently 3-4x slower than native, `shellcheck.executablePath` is ignored, and files outside the document's workspace folder are not visible to `source` directives or `.shellcheckrc` lookup.
      #  - auto: Run the shellcheck executable on desktop and WebAssembly in VS Code for the Web.
      #  - native: Run the bundled or user-provided shellcheck executable.
      #  - wasm: Run the bundled WebAssembly build of ShellCheck (experimental, slower).
      runtime = "auto";

      # Seconds a `shellcheck` run may take before it is stopped. `0` uses the default, 30 seconds. A stopped run leaves the document's problems as they were. Only runs started after a change are stopped: a document whose run already hangs is linted again once it is closed and reopened.
      runTimeout = 0;

      # Whether to use the workspace root directory as the current working directory when launching `shellcheck`. Otherwise, the directory of the file being linted will be used.
      useWorkspaceRootAsCwd = false;

      # Native Runtime
      # Whether to disable shellcheck binary version check, which prompts for updating when an outdated version is found. The check only runs when `shellcheck.runtime` is `native`, so it has no effect in VS Code for the Web.
      disableVersionCheck = false;

      # Path to the `shellcheck` executable (bundled binaries will be used if empty). Only used when `shellcheck.runtime` is `native`, so it has no effect in VS Code for the Web.
      executablePath = "";

      watchConfigFiles = {
        # Config Files
        # Lint open documents again when a ShellCheck config file outside the workspace is created, changed or deleted: a `.shellcheckrc` or `shellcheckrc` in a folder above a workspace folder, `~/.shellcheckrc` and `$XDG_CONFIG_HOME/shellcheckrc` (`%APPDATA%\shellcheckrc` on Windows), and a file passed with `--rcfile` in `shellcheck.customArgs` that lives outside the workspace. Only used when `shellcheck.runtime` is `native`, the only runtime that can read these files, so it has no effect in VS Code for the Web.
        user = false;

        # Lint open documents again when a `.shellcheckrc` or `shellcheckrc` in the workspace is created, changed or deleted, along with a file passed with `--rcfile` in `shellcheck.customArgs` that lives in the workspace. Only the documents that can pick up the changed file are linted again, and never those passed `--norc`.
        workspace = false;
      };
    };

    # Configure glob patterns for excluding files and folders by ShellCheck. Glob patterns are interpreted relative to the workspace's root folder and use [picomatch](https://github.com/micromatch/picomatch#readme) syntax, which also supports extglob patterns such as `!(*.*)`.
    "shellcheck.ignorePatterns" = {
      "**/*.csh" = true;
      "**/*.cshrc" = true;
      "**/*.fish" = true;
      "**/*.login" = true;
      "**/*.logout" = true;
      "**/*.tcsh" = true;
      "**/*.tcshrc" = true;
      "**/*.xonshrc" = true;
      "**/*.xsh" = true;
      "**/*.zsh" = true;
      "**/*.zshrc" = true;
      "**/zshrc" = true;
      "**/*.zprofile" = true;
      "**/zprofile" = true;
      "**/*.zlogin" = true;
      "**/zlogin" = true;
      "**/*.zlogout" = true;
      "**/zlogout" = true;
      "**/*.zshenv" = true;
      "**/zshenv" = true;
      "**/*.zsh-theme" = true;
    };

    shfmt = {
      #~@ shfmt
      # Additional arguments to pass to the shfmt executable
      executableArgs = [];

      # Path to or name of the shfmt executable
      executablePath = "shfmt";

      # Format files marked `ignore` with [EditorConfig](https://editorconfig.org/)? (shfmt itself only ignores them when scanning directories.)
      formatIgnored = true;
    };

    lintRunner = {
      tools = {
        shellcheck = {
          kind = "diagnostic";
          command = "shellcheck";
          args = [
            "--enable=all"
            "--format=gcc"
            "\${file}"
          ];
          successExitCodes = [
            0
            1
          ];
          parser = {
            flags = "gm";
            pattern = "^.+?:(?<line>\\\\d+):(?<col>\\\\d+): (?<severity>error|warning|note): (?<message>.+)$";
          };
        };
      };

      targets = [
        {
          name = "Shell";
          match = {
            languages = [
              "shellscript"
            ];
          };
          onOpen = {
            strategy = "sequence";
            tools = [
              "shellcheck"
            ];
          };
          onSave = {
            strategy = "sequence";
            tools = [
              "shellcheck"
            ];
          };
        }
      ];
    };
  };
in {inherit enable extensions options settings;}
