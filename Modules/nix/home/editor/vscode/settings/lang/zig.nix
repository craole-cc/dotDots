{
  context,
  mkEnable,
  requires,
  ...
}: let
  lang = "rust";
  condition = requires lang;
  enable = condition;
  options.${lang}.enable = mkEnable {inherit context condition;};

  defaultFormatter = "ziglang.vscode-zig";
  extensions = [
    defaultFormatter
    "formulahendry.code-runner"
    "vadimcn.vscode-lldb"
  ];

  settings = {
    "[${lang}]" = {
      editor = {
        inherit defaultFormatter;
        stickyScroll.defaultModel = "foldingProviderModel";
      };
    };
    ${lang} = {
      #> Control how build errors are printed. Only applies to the `zig build subcommand`.
      #?  - verbose: Report errors with full context.
      #?  - minimal: Report errors after summary, excluding context like command lines.
      #?  - verboseClear: Like 'verbose', but clear the terminal at the start of each update.
      #?  - minimalClear: Like 'minimal', but clear the terminal at the start of each update.
      buildErrorStyle = "verbose";

      #> Control how multi-line error messages are printed. Only applies to the `zig build subcommand`.
      #?  - indent: Indent non-initial lines to align with initial line.
      #?  - newline: Include a leading newline so that the error message is on its own lines.
      #?  - none: Print as usual so the first line is misaligned.
      buildMultilineErrors = "indent";

      #> Specify which additional arguments should be passed to `zig build` when running build on save. Use the `--build-file` argument to override which build file should be used.
      buildOnSaveArgs = [];

      #> Specify how build on save diagnostics should be provided.
      #?  - off: Disable build on save
      #?  - auto: Disabled unless ZLS has enabled [build on save](https://zigtools.org/zls/guides/build-on-save/) automatically.
      #?  - extension: Provide build on save by running `zig build --watch`
      #?  - zls: Provide build on save using ZLS
      buildOnSaveProvider = "extension";

      #> The debug adapter command to run when starting a debug session
      debugAdapter = "lldb";

      #> Arguments to pass to 'zig' for debugging tests. Supported variables: `${filter}`, `${path}`, `${binaryPath}`.
      #? To debug a test with a build script add a step that installs the test binary at `zig-out/bin/debug-unit-tests`:
      #? ```zig
      #? b.step("debug-test-unit", "Debug unit tests").dependOn(&b.addInstallArtifact(unit_tests, .{ .dest_sub_path = "debug-unit-tests" }).step);
      #? ```
      debugTestArgs = [
        "test"
        "\${path}"
        "--test-filter"
        "\${filter}"
        "--test-no-exec"
        "-femit-bin=\${binaryPath}"
      ];

      #> Whether to enable formatting
      #?  - off: Disable formatting
      #?  - extension: Provide formatting by directly invoking `zig fmt`
      #?  - zls: Provide formatting by using ZLS (which matches `zig fmt`)
      formattingProvider = "zls";

      #> Override the Zig library path. Will be automatically resolved by the Zig compiler.
      libPath = "";

      #> Set a custom path to the `zig` executable. Example: `C:/zig-windows-x86_64-0.13.0/zig.exe`. The string "zig" means lookup zig in PATH.
      path = "";

      #> Arguments to pass to 'zig' for running tests. Supported variables: `${filter}`, `${path}`.
      #? To use test filter with a build script define a custom option to pass it to: `-Dtest-filter=${filter}`.
      testArgs = [
        "test"
        "--test-filter"
        "\${filter}"
        "\${path}"
      ];

      #> Specify which Zig version should be installed. Takes priority over a `.zigversion` file or a `build.zig.zon` with `minimum_zig_version`.
      version = "";

      zls = {
        #> Additional config options that should be forwarded to ZLS. Every property must have the format 'zig.zls.someOptionName'. You will **not** be warned about unused or ignored options.
        additionalOptions = {};

        #> Specify a custom build runner to resolve build system information.
        buildRunnerPath = "";

        #> Override the path to 'builtin' module. Automatically resolved if unset.
        builtinPath = "";

        #> Whether to show the function signature in completion results. May improve readability in some editors when disabled
        completionLabelDetails = true;

        #> Whether to enable function argument placeholder completions
        enableArgumentPlaceholders = true;

        #> Whether to enable the optional ZLS language server
        #?  - ask: Prompt to enable ZLS for the workspace on first use (default)
        #?  - on: Always enable ZLS
        #?  - off: Never enable ZLS
        enabled = "on";

        #> Enables snippet completions when the client also supports them
        enableSnippets = true;

        #> Path to a directory that will be used as zig's cache. Will default to `${KnownFolders.Cache}/zls`.
        globalCachePath = "";

        #> Whether to highlight global var declarations
        highlightGlobalVarDeclarations = true;

        #> Don't show inlay hints for single argument calls
        inlayHintsExcludeSingleArgument = false;

        #> Hides inlay hints when parameter name matches the identifier (e.g. `foo: foo`)
        inlayHintsHideRedundantParamNames = false;

        #> Hides inlay hints when parameter name matches the last token of a parameter node (e.g. `foo: bar.foo`, `foo: &foo`)
        inlayHintsHideRedundantParamNamesLastToken = false;

        #> Enable inlay hints for builtin functions
        inlayHintsShowBuiltin = true;

        #> Enable inlay hints for parameter names
        inlayHintsShowParameterName = true;

        #> Enable inlay hints for fields in struct and union literals
        inlayHintsShowStructLiteralFieldType = true;

        #> Enable inlay hints for variable types
        inlayHintsShowVariableTypeHints = true;

        #> Set a custom path to the `zls` executable. Example: `C:/zls/zig-cache/bin/zls.exe`. The string "zls" means lookup ZLS in PATH.
        path = "";

        #> Favor using `zig ast-check` instead of the builtin one
        preferAstCheckAsChildProcess = true;

        #> Set level of semantic tokens. `partial` only includes information that requires semantic analysis; this will usually give a better result than `full` in VS Code thanks to the Zig extension's syntax file.
        #?  - partial: Only emit semantic tokens where syntactic highlighting isn't enough (default)
        #?  - full: Emit semantic tokens for everything ZLS can classify
        #?  - none: Disable semantic tokens entirely
        semanticTokens = "partial";

        #> When true, skips searching for references in the standard library. Improves lookup speed for functions in user's code. Renaming and go-to-definition will continue to work as is
        #? Only affects "Find All References" / "Call Hierarchy" style queries that would otherwise walk into `std`. Go-to-definition and rename are unaffected and still resolve stdlib symbols.
        #? Tradeoff: with this enabled, references to a stdlib symbol (e.g. every call site of `std.mem.sort`) are no longer found, which is rarely what you want unless your workspace is large or the stdlib search is slow.
        #?  - true: Skip the standard library when searching for references (faster, fewer results)
        #?  - false: Include the standard library in reference searches (slower, complete results)
        skipStdReferences = false;

        trace = {
          #> Traces the communication between VS Code and the ZLS language server.
          #? The log output can be accessed by running the "Developer: Show Logs..." command and selecting "ZLS language server". To display trace messages, use "Developer: Set Log Level..." or click the settings (⚙️) icon in the top-right corner of the output panel.
          server = "off";
        };

        #> Enables warnings for style guideline mismatches
        warnStyle = true;
      };
    };

    code-runner = {
      #> Run in the integrated terminal instead of the read-only Output panel. Required for interactive programs (stdin, TUI, etc.).
      runInTerminal = true;

      #> Save the file before running, so you never run stale code.
      saveFileBeforeRun = true;

      #> Keep focus in the editor after running instead of jumping to the terminal.
      preserveFocus = false;

      #> Clear previous output before each run.
      clearPreviousOutput = true;

      #> Per-language run commands. Replaces the built-in map for listed languages; unlisted languages keep their built-in defaults.
      #? For Zig, go through the build system so `@import` and the module graph resolve correctly:
      #?  - `zig build run` requires a `run` step in `build.zig` (present in `zig init` projects).
      #?  - Use `zig run $fileName` only for self-contained single-file scripts.
      executorMap = {
        zig = "cd $dir && zig build run";
      };
    };
  };
in {inherit enable extensions options settings;}
