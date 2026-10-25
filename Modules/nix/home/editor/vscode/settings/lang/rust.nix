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

  defaultFormatter = "rust-lang.rust-analyzer";
  extensions = [
    defaultFormatter
    "fill-labs.dependi"
    "vadimcn.vscode-lldb"
    "hbenl.vscode-test-explorer"
    "ms-vscode.test-adapter-converter"
    "Swellaby.vscode-rust-test-adapter"
  ];

  settings = {
    dependi.rust = {
      #> Enable checking for Rust dependencies.
      enabled = true;
      #> Matches lines based on `*` position: `text*`, `*text`, `*text*`. Multiple patterns can be used, separated by commas.
      ignoreLinePatterns = "";
      #> The URL for the Rust package index server.
      indexServerURL = "https://index.crates.io";
      #> Inform about available patch updates for Rust packages via decoration.
      informPatchUpdates = false;
      #> Enable checking for Rust dependencies in lockfiles.
      lockFileEnabled = true;
      #> Consider non-registry packages as up-to-date if their version exceeds the max.
      silenceVersionOverflows = false;
      #> Filter unstable versions: Exclude, Include Always, or Include If Unstable.
      #?  - Exclude: Exclude them (default)
      #?  - IncludeAlways: Include them and always consider as latest
      #?  - IncludeIfUnstable: Include if the current version is already unstable
      unstableFilter = "Exclude";
    };

    rust-analyzer = {
      #> Run the check command for diagnostics on save.
      checkOnSave = true;
      #> Disable support for `#[rust_analyzer::rust_fixture]` snippets.
      #? If you are not working on rust-analyzer itself, you should ignore this config.
      disableFixtureSupport = false;
      #> Do not start rust-analyzer server when the extension is activated.
      initializeStopped = false;
      #> Disable project auto-discovery in favor of explicitly specified set of projects.
      #? Elements must be paths pointing to `Cargo.toml`, `rust-project.json`, `.rs` files (which will be treated as standalone files) or JSON objects in `rust-project.json` format.
      linkedProjects = [];
      #? The number of worker threads in the main loop. The default `null` means to pick automatically.
      numThreads = null;

      projectCreation = {
        #> Control what happens after `rust-analyzer: Create New Project...` finishes creating a Cargo project.
        #?  - ask: Prompt for how to open the new project.
        #?  - open: Open the new project in the current window.
        #?  - openNewWindow: Open the new project in a new window.
        #?  - addToWorkspace: Add the new project to the current workspace, or open it if no workspace is open.
        openAfterCreate = "ask";
      };

      #> Restart the server automatically when settings that require a restart are changed.
      restartServerOnConfigChange = false;
      #> Show Rust Dependencies in the Explorer view.
      showDependenciesExplorer = true;
      #> Show error notifications when requests fail.
      showRequestFailedErrorNotification = true;
      #> Show Syntax Tree in the Explorer view.
      showSyntaxTree = false;
      #> Show a notification for unlinked files, prompting the user to add the corresponding Cargo.toml to the linked projects setting.
      showUnlinkedFileNotification = true;
      #> Show the Test Explorer view.
      testExplorer = false;

      runnables = {
        #> Ask before updating the test when running it.
        askBeforeUpdateTest = true;

        bench = {
          #> Subcommand used for bench runnables instead of `bench`.
          command = "bench";
          #> Override the command used for bench runnables.
          #? The first element of the array should be the program to execute (for example,`cargo`).
          #? Use the placeholders:
          #? - `${package}`: package name.
          #? - `${target_arg}`: target option such as `--bin`, `--test`, `--lib`, etc.
          #? - `${target}`: target name (empty for `--lib`).
          #? - `${test_name}`: the test path filter, e.g. `module::bench_func`.
          #? - `${exact}`: `--exact` for single benchmarks, empty for modules.
          #? - `${include_ignored}`: always empty for benchmarks.
          #? - `${executable_args}`: all of the above binary args bundled together
          #?     (includes `rust-analyzer.runnables.extraTestBinaryArgs`).
          overrideCommand = null;
        };

        #> Command to be executed instead of 'cargo' for runnables.
        command = null;

        doctest = {
          #> Override the command used for doc-test runnables.
          #? The first element of the array should be the program to execute (for example, `cargo`).
          #? Use the placeholders:
          #? - `${package}`: package name.
          #? - `${target_arg}`: target option such as `--bin`, `--test`, `--lib`, etc.
          #? - `${target}`: target name (empty for `--lib`).
          #? - `${test_name}`: the test path filter, e.g. `module::func`.
          #? - `${exact}`: always empty for doc-tests.
          #? - `${include_ignored}`: always empty for doc-tests.
          #? - `${executable_args}`: all of the above binary args bundled together
          #?     (includes `rust-analyzer.runnables.extraTestBinaryArgs`).
          overrideCommand = null;
        };

        #> Additional arguments to be passed to cargo for runnables such as tests or binaries. For example, it may be `--release`.
        extraArgs = [];

        #> Environment variables passed to the runnable launched using `Test` or `Debug` lens or `rust-analyzer.run` command.
        extraEnv = null;

        #> Additional arguments to be passed through Cargo to launched tests, benchmarks, or doc-tests.
        #? Unless the launched target uses a [custom test harness](https://doc.rust-lang.org/cargo/reference/cargo-targets.html#the-harness-field), they will end up being interpreted as options to [`rustc`’s built-in test harness (“libtest”)](https://doc.rust-lang.org/rustc/tests/index.html#cli-arguments).
        extraTestBinaryArgs = [
          "--nocapture"
        ];

        #> Problem matchers to use for `rust-analyzer.run` command, eg `["$rustc", "$rust-panic"]`.
        problemMatcher = [
          "$rustc"
        ];

        test = {
          #> Subcommand used for test runnables instead of `test`.
          command = "test";
          #> Override the command used for test runnables.
          #? The first element of the array should be the program to execute (for example, `cargo`).
          #? Available placeholders:
          #? - `${package}`: package name.
          #? - `${target_arg}`: target option such as `--bin`, `--test`, `--lib`, etc.
          #? - `${target}`: target name (empty for `--lib`).
          #? - `${test_name}`: the test path filter, e.g. `module::test_func`.
          #? - `${exact}`: `--exact` for single tests, empty for modules.
          #? - `${include_ignored}`: `--include-ignored` for single tests, empty otherwise.
          #? - `${executable_args}`: all of the above binary args bundled together
          #?     (includes `rust-analyzer.runnables.extraTestBinaryArgs`).
          overrideCommand = null;
        };
      };

      statusBar = {
        #> Action to run when clicking the extension status bar item.
        #?  - stopServer: Stop Server
        #?  - openLogs: Open Logs
        clickAction = "openLogs";

        #> When to show the extension status bar.
        #? `"always"` Always show the status bar.
        #? `"never"` Never show the status bar.
        #? `{ documentSelector: <DocumentSelector>[] }` Show the status bar if the open file matches any of the given document selectors.
        #? See [VS Code -- DocumentSelector](https://code.visualstudio.com/api/references/document-selector) for more information.
        showStatusBar = {
          documentSelector = [
            {language = "rust";}
            {pattern = "**/Cargo.toml";}
            {pattern = "**/Cargo.lock";}
            {
              scheme = "output";
              pattern = "extension-output-rust-lang.rust-analyzer*";
            }
          ];
        };
      };

      server = {
        #> Extra environment variables that will be passed to the rust-analyzer executable. Useful for passing e.g. `RA_LOG` for debugging.
        extraEnv = null;
        #> Path to rust-analyzer executable (points to bundled binary by default).
        path = null;
      };

      trace = {
        #> Log level is now controlled by the [Developer: Set Log Level...](command:workbench.action.setLogLevel) command. You can set the log level for the current session and also the default log level from there. This is also available by clicking the gear icon on the OUTPUT tab when rust-analyzer Extension is visible or by passing the --log rust-lang.rust-analyzer:debug parameter to VS Code.
        #> Enable logging of VS Code extensions itself.
        extension = false;
        #> Trace requests to the rust-analyzer (this is usually overly verbose and not recommended for regular users).
        #?  - off: No traces
        #?  - messages: Error only
        #?  - verbose: Full log
        server = "off";
      };

      debug = {
        #> Whether to rebuild the project modules before debugging the same test again
        buildBeforeRestart = false;
        #> Preferred debug engine.
        #?  - auto: Use the first available extension out of [LLDB DAP](https://marketplace.visualstudio.com/items?itemName=llvm-vs-code-extensions.lldb-dap), [CodeLLDB](https://marketplace.visualstudio.com/items?itemName=vadimcn.vscode-lldb), [C/C++ for Visual Studio Code](https://marketplace.visualstudio.com/items?itemName=ms-vscode.cpptools), and [Native Debug](https://marketplace.visualstudio.com/items?itemName=webfreak.debug).
        #?  - llvm-vs-code-extensions.lldb-dap: Use [LLDB DAP](https://marketplace.visualstudio.com/items?itemName=llvm-vs-code-extensions.lldb-dap)
        #?  - vadimcn.vscode-lldb: Use [CodeLLDB](https://marketplace.visualstudio.com/items?itemName=vadimcn.vscode-lldb)
        #?  - ms-vscode.cpptools: Use [C/C++ for Visual Studio Code](https://marketplace.visualstudio.com/items?itemName=ms-vscode.cpptools)
        #?  - webfreak.debug: Use [Native Debug](https://marketplace.visualstudio.com/items?itemName=webfreak.debug)
        engine = "auto";
        #> Optional settings passed to the debug engine. Example: `{ "lldb": { "terminal":"external"} }`
        engineSettings = {};
        #> Optional source file mappings passed to the debug engine.
        sourceFileMap = {
          "/rustc/<id>" = "\${env:USERPROFILE}/.rustup/toolchains/<toolchain-id>/lib/rustlib/src/rust";
        };
      };

      typing = {
        #> Whether to prefix newlines after comments with the corresponding comment prefix.
        continueCommentsOnNewline = true;
        #> Specify the characters allowed to invoke special on typing triggers.
        #? - typing `=` after `let` tries to smartly add `;` if `=` is followed by an existing expression
        #? - typing `=` between two expressions adds `;` when in statement position
        #? - typing `=` to turn an assignment into an equality comparison removes `;` when in expression position
        #? - typing `.` in a chain method call auto-indents
        #? - typing `{` or `(` in front of an expression inserts a closing `}` or `)` after the expression
        #? - typing `{` in a use item adds a closing `}` in the right place
        #? - typing `>` to complete a return type `->` will insert a whitespace after it
        #? - typing `<` in a path or type position inserts a closing `>` after the path or type.
        triggerChars = "=.";
      };

      diagnostics = {
        #> List of rust-analyzer diagnostics to disable.
        disabled = [];
        #> Show native rust-analyzer diagnostics.
        enable = true;
        experimental = {
          #> Show experimental rust-analyzer diagnostics that might have more false positives than usual.
          enable = false;
        };
        #> Whether to show the main part of the rendered rustc output of a diagnostic message.
        previewRustcOutput = false;
        #> Map of prefixes to be substituted when parsing diagnostic file paths. This should be the reverse mapping of what is passed to `rustc` as `--remap-path-prefix`.
        remapPrefix = {};
        styleLints = {
          #> Run additional style lints.
          enable = false;
        };
        #> Whether to show diagnostics using the original rustc error code. If this is false, all rustc diagnostics will have the code 'rustc(Click for full compiler diagnostics)'
        useRustcErrorCode = false;
        #> List of warnings that should be displayed with hint severity.
        #? The warnings will be indicated by faded text or three dots in code and will not show up in the `Problems Panel`.
        warningsAsHint = [];
        #> List of warnings that should be displayed with info severity.
        #? The warnings will be indicated by a blue squiggly underline in code and a blue icon in the `Problems Panel`.
        warningsAsInfo = [];
      };

      assist = {
        #> Insert #[must_use] when generating `as_` methods for enum variants.
        emitMustUse = false;
        #> Placeholder expression to use for missing expressions in assists.
        #?  - todo: Fill missing expressions with the `todo` macro
        #?  - default: Fill missing expressions with reasonable defaults, `new` or `default` constructors.
        expressionFillDefault = "todo";
        #> Prefer to use `Self` over the type name when inserting a type (e.g. in "fill match arms" assist).
        preferSelf = false;
        termSearch = {
          #> Term search fuel in "units of work" for assists (Defaults to 1800).
          fuel = 1800;
        };
      };

      cachePriming = {
        #> Warm up caches on project load.
        enable = true;
        #> How many worker threads to handle priming caches. The default `0` means to pick automatically.
        numThreads = "physical";
      };

      cargo = {
        #> Pass `--all-targets` to cargo invocation.
        allTargets = true;
        #> Automatically refresh project info via `cargo metadata` on `Cargo.toml` or `.cargo/config.toml` changes.
        autoreload = true;
        buildScripts = {
          #> Run build scripts (`build.rs`) for more precise code analysis.
          enable = true;
          #> Specifies the invocation strategy to use when running the build scripts command.
          #? If `per_workspace` is set, the command will be executed for each Rust workspace with the workspace as the working directory.
          #? If `once` is set, the command will be executed once with the opened project as the working directory.
          #? This config only has an effect when `rust-analyzer.cargo.buildScripts.overrideCommand` is set.
          #?  - per_workspace: The command will be executed for each Rust workspace with the workspace as the working directory.
          #?  - once: The command will be executed once with the opened project as the working directory.
          #? **Warning:** This can cause errors when the Cargo configuration of the opened workspaces is different or even only different than the default. Enabling this is not recommended.
          invocationStrategy = "per_workspace";
          #> Override the command rust-analyzer uses to run build scripts and build procedural macros. The command is required to output json and should therefore include `--message-format=json` or a similar option.
          #? If there are multiple linked projects/workspaces, this command is invoked for each of them, with the working directory being the workspace root (i.e., the folder containing the `Cargo.toml`). This can be overwritten by changing `rust-analyzer.cargo.buildScripts.invocationStrategy`.
          #? By default, a cargo invocation will be constructed for the configured targets and features, with the following base command line:
          #? ```bash
          #? cargo check --quiet --workspace --message-format=json --all-targets --keep-going
          #? ```
          #? Note: The option must be specified as an array of command line arguments, with the first argument being the name of the command to run.
          overrideCommand = null;
          #> Rerun proc-macros building/build-scripts running when proc-macro or build-script sources change and are saved.
          rebuildOnSave = true;
          #> Use `RUSTC_WRAPPER=rust-analyzer` when running build scripts to avoid checking unnecessary things.
          useRustcWrapper = true;
        };
        #> List of cfg options to enable with the given values.
        #? To enable a name without a value, use `"key"`.
        #? To enable a name with a value, use `"key=value"`.
        #? To disable, prefix the entry with a `!`.
        cfgs = [
          "debug_assertions"
          "miri"
        ];
        #> Path to a `.cargo/config.toml` style file to pass to cargo via `--config` for every cargo invocation (metadata, build scripts, config discovery). Useful to give rust-analyzer a consistent view of the project configuration.
        configPath = null;
        #> Extra arguments that are passed to every cargo invocation.
        extraArgs = [];
        #> Extra environment variables that will be set when running cargo, rustc or other commands within the workspace. Useful for setting RUSTFLAGS.
        extraEnv = {};
        #> List of features to activate.
        #? Set this to `"all"` to pass `--all-features` to cargo.
        features = [];
        #> Extra arguments passed only to `cargo metadata`, not to other cargo invocations. Useful for flags like `--config` that `cargo metadata` supports.
        metadataExtraArgs = [];
        #> Whether to pass `--no-default-features` to cargo.
        noDefaultFeatures = false;
        #> Whether to skip fetching dependencies. If set to "true", the analysis is performed entirely offline, and Cargo metadata for dependencies is not fetched.
        noDeps = false;
        #> Relative path to the sysroot, or "discover" to try to automatically find it via "rustc --print sysroot".
        #? Unsetting this disables sysroot loading.
        #? This option does not take effect until rust-analyzer is restarted.
        sysroot = "discover";
        #> Relative path to the sysroot library sources. If left unset, this will default to `{cargo.sysroot}/lib/rustlib/src/rust/library`.
        #? This option does not take effect until rust-analyzer is restarted.
        sysrootSrc = null;
        #> Compilation target override (target tuple).
        target = null;
        #> Optional path to a rust-analyzer specific target directory.
        #? This prevents rust-analyzer's `cargo check` and initial build-script and proc-macro building from locking the `Cargo.lock` at the expense of duplicating build artifacts.
        #? Set to `true` to use a subdirectory of the existing target directory or set to a path relative to the workspace to use that path.
        targetDir = null;
      };

      cfg = {
        #> Set `cfg(test)` for local crates. Defaults to true.
        setTest = true;
      };

      check = {
        #> Check all targets and tests (`--all-targets`). Defaults to `rust-analyzer.cargo.allTargets`.
        allTargets = null;
        #> Cargo command to use for `cargo check`.
        command = "clippy";
        #> Extra arguments for `cargo check`.
        extraArgs = [];
        #> Extra environment variables that will be set when running `cargo check`. Extends `rust-analyzer.cargo.extraEnv`.
        extraEnv = {};
        #> List of features to activate. Defaults to `rust-analyzer.cargo.features`.
        #? Set to `"all"` to pass `--all-features` to Cargo.
        features = null;
        #> List of `cargo check` (or other command specified in `check.command`) diagnostics to ignore.
        #? For example for `cargo check`: `dead_code`, `unused_imports`, `unused_variables`,...
        ignore = [];
        #> Specifies the invocation strategy to use when running the check command.
        #? If `per_workspace` is set, the command will be executed for each workspace.
        #? If `once` is set, the command will be executed once.
        #? This config only has an effect when `rust-analyzer.check.overrideCommand` is set.
        #?  - per_workspace: The command will be executed for each Rust workspace with the workspace as the working directory.
        #?  - once: The command will be executed once with the opened project as the working directory.
        #? **Warning:** This can cause errors when the Cargo configuration of the opened workspaces is different or even only different than the default. Enabling this is not recommended.
        invocationStrategy = "per_workspace";
        #> Whether to pass `--no-default-features` to Cargo. Defaults to `rust-analyzer.cargo.noDefaultFeatures`.
        noDefaultFeatures = null;
        #> Override the command rust-analyzer uses instead of `cargo check` for diagnostics on save. The command is required to output json and should therefore include `--message-format=json` or a similar option (if your client supports the `colorDiagnosticOutput` experimental capability, you can use `--message-format=json-diagnostic-rendered-ansi`).
        #? If you're changing this because you're using some tool wrapping Cargo, you might also want to change `rust-analyzer.cargo.buildScripts.overrideCommand`.
        #? If there are multiple linked projects/workspaces, this command is invoked for each of them, with the working directory being the workspace root (i.e., the folder containing the `Cargo.toml`). This can be overwritten by changing `rust-analyzer.check.invocationStrategy`.
        #? It supports two interpolation syntaxes, both mainly intended to be used with [non-Cargo build systems](./non_cargo_based_projects.md):
        #? - If `{saved_file}` is part of the command, rust-analyzer will pass the absolute path of the saved file to the provided command. (A previous version, `$saved_file`, also works.)
        #? - If `{label}` is part of the command, rust-analyzer will pass the Cargo package ID, which can be used with `cargo check -p`, or a build label from `rust-project.json`. If `{label}` is included, rust-analyzer behaves much like [`"rust-analyzer.check.workspace": false`](#check.workspace).
        #? An example command would be:
        #? ```bash
        #? cargo check --workspace --message-format=json --all-targets
        #? ```
        #? Note: The option must be specified as an array of command line arguments, with the first argument being the name of the command to run.
        overrideCommand = null;
        #> Check for specific targets. Defaults to `rust-analyzer.cargo.target` if empty.
        #? Can be a single target, e.g. `"x86_64-unknown-linux-gnu"` or a list of targets, e.g. `["aarch64-apple-darwin", "x86_64-apple-darwin"]`.
        #? Aliased as `"checkOnSave.targets"`.
        targets = null;
        #> Whether `--workspace` should be passed to `cargo check`.
        #? If false, `-p <package>` will be passed instead if applicable. In case it is not, no check will be performed.
        workspace = true;
      };

      completion = {
        #> Automatically add `::` when completing the module.
        #? Will not be completed in `use`.
        addColonsToModule = true;
        #> Automatically add a semicolon when completing unit-returning functions.
        #? In `match` arms it completes a comma instead.
        addSemicolonToUnit = true;
        autoAwait = {
          #> Show method calls and field accesses completions with `await` prefixed to them when completing on a future.
          enable = true;
        };
        autoimport = {
          #> Show completions that automatically add imports when completed.
          #? Note that your client must specify the `additionalTextEdits` LSP client capability to truly have this feature enabled.
          enable = true;
          #> A list of full paths to items to exclude from auto-importing completions.
          #? Traits in this list won't have their methods suggested in completions unless the trait is in scope.
          #? You can either specify a string path which defaults to type "always" or use the more verbose form `{ "path": "path::to::item", type: "always" }`.
          #? For traits the type "methods" can be used to only exclude the methods but not the trait itself.
          #? For modules the type "sub_items" can be used to only exclude the all items in it but not the module itself. This does not include items defined in nested modules.
          #? For enums the type "variants" can be used to only exclude the all variants in it but not the enum itself.
          #? This setting also inherits `rust-analyzer.completion.excludeTraits`.
          exclude = [
            {
              path = "core::borrow::Borrow";
              type = "methods";
            }
            {
              path = "core::borrow::BorrowMut";
              type = "methods";
            }
          ];
        };
        autoIter = {
          #> Show method call completions with `iter()` or `into_iter()` prefixed to them when completing on a type that has them.
          enable = true;
        };
        autoself = {
          #> Show method calls and field access completions with `self` prefixed to them when inside a method.
          enable = true;
        };
        callable = {
          #> Add parenthesis and argument snippets when completing function.
          #?  - fill_arguments: Add call parentheses and pre-fill arguments.
          #?  - add_parentheses: Add call parentheses.
          #?  - none: Do no snippet completions for callables.
          snippets = "fill_arguments";
        };
        #> A list of full paths to traits whose methods to exclude from completion.
        #? Methods from these traits won't be completed, even if the trait is in scope. However, they will still be suggested on expressions whose type is `dyn Trait`, `impl Trait` or `T where T: Trait`.
        #? Note that the trait themselves can still be completed.
        excludeTraits = [];
        fullFunctionSignatures = {
          #> Show full function / method signatures in completion docs.
          enable = false;
        };
        #> Omit deprecated items from completions. By default they are marked as deprecated but not hidden.
        hideDeprecated = false;
        #> Maximum number of completions to return. If `None`, the limit is infinite.
        limit = null;
        postfix = {
          #> Show postfix snippets like `dbg`, `if`, `not`, etc.
          enable = true;
        };
        privateEditable = {
          #> Show completions of private items and fields that are defined in the current workspace even if they are not visible at the current position.
          enable = false;
        };
        snippets = {
          #> Custom completion snippets.
          custom = {
            Ok = {
              postfix = "ok";
              body = "Ok(\${receiver})";
              description = "Wrap the expression in a `Result::Ok`";
              scope = "expr";
            };
            "Box::pin" = {
              postfix = "pinbox";
              body = "Box::pin(\${receiver})";
              requires = "std::boxed::Box";
              description = "Put the expression into a pinned `Box`";
              scope = "expr";
            };
            "Arc::new" = {
              postfix = "arc";
              body = "Arc::new(\${receiver})";
              requires = "std::sync::Arc";
              description = "Put the expression into an `Arc`";
              scope = "expr";
            };
            Some = {
              postfix = "some";
              body = "Some(\${receiver})";
              description = "Wrap the expression in an `Option::Some`";
              scope = "expr";
            };
            Err = {
              postfix = "err";
              body = "Err(\${receiver})";
              description = "Wrap the expression in a `Result::Err`";
              scope = "expr";
            };
            "Rc::new" = {
              postfix = "rc";
              body = "Rc::new(\${receiver})";
              requires = "std::rc::Rc";
              description = "Put the expression into an `Rc`";
              scope = "expr";
            };
          };
        };
        termSearch = {
          #> Enable term search based snippets like `Some(foo.bar().baz())`.
          enable = false;
          #> Term search fuel in "units of work" for autocompletion (Defaults to 1000).
          fuel = 1000;
        };
        turbofish = {
          #> Complete turbofish (`::<>`) at the call site (if needed).
          enable = true;
        };
      };

      document = {
        symbol = {
          search = {
            #> Exclude all locals from document symbol search.
            excludeLocals = true;
          };
        };
      };

      files = {
        #> List of files to ignore
        #? These paths (file/directories) will be ignored by rust-analyzer. They are relative to the workspace root, and globs are not supported. You may also need to add the folders to Code's `files.watcherExclude`.
        exclude = [];
        #> Controls file watching implementation.
        #?  - client: Use the client (editor) to watch files for changes
        #?  - server: Use server-side file watching
        watcher = "client";
      };

      gotoImplementations = {
        #> If this is `true`, when "Goto Implementations" and in "Implementations" lens, are triggered on a `struct` or `enum` or `union`, we filter out trait implementations that originate from `derive`s above the type.
        filterAdjacentDerives = false;
      };

      highlightRelated = {
        branchExitPoints = {
          #> Highlight related return values while the cursor is on any `match`, `if`, or match arm arrow (`=>`).
          enable = true;
        };
        breakPoints = {
          #> Highlight related references while the cursor is on `break`, `loop`, `while`, or `for` keywords.
          enable = true;
        };
        closureCaptures = {
          #> Highlight all captures of a closure while the cursor is on the `|` or move keyword of a closure.
          enable = true;
        };
        exitPoints = {
          #> Highlight all exit points while the cursor is on any `return`, `?`, `fn`, or return type arrow (`->`).
          enable = true;
        };
        references = {
          #> Highlight related references while the cursor is on any identifier.
          enable = true;
        };
        yieldPoints = {
          #> Highlight all break points for a loop or block context while the cursor is on any `async` or `await` keywords.
          enable = true;
        };
      };

      hover = {
        actions = {
          debug = {
            #> Show `Debug` action. Only applies when `rust-analyzer.hover.actions.enable` is set.
            enable = true;
          };
          #> Show HoverActions in Rust files.
          enable = true;
          gotoTypeDef = {
            #> Show `Go to Type Definition` action. Only applies when `rust-analyzer.hover.actions.enable` is set.
            enable = true;
          };
          implementations = {
            #> Show `Implementations` action. Only applies when `rust-analyzer.hover.actions.enable` is set.
            enable = true;
          };
          references = {
            #> Show `References` action. Only applies when `rust-analyzer.hover.actions.enable` is set.
            enable = false;
          };
          run = {
            #> Show `Run` action. Only applies when `rust-analyzer.hover.actions.enable` is set.
            enable = true;
          };
          updateTest = {
            #> Show `Update Test` action. Only applies when `rust-analyzer.hover.actions.enable` and `rust-analyzer.hover.actions.run.enable` are set.
            enable = true;
          };
        };
        documentation = {
          #> Show documentation on hover.
          enable = true;
          keywords = {
            #> Show keyword hover popups. Only applies when `rust-analyzer.hover.documentation.enable` is set.
            enable = true;
          };
        };
        dropGlue = {
          #> Show drop glue information on hover.
          enable = true;
        };
        links = {
          #> Use markdown syntax for links on hover.
          enable = true;
        };
        #> Show what types are used as generic arguments in calls etc. on hover, and limit the max length to show such types, beyond which they will be shown with ellipsis.
        #? This can take three values: `null` means "unlimited", the string `"hide"` means to not show generic substitutions at all, and a number means to limit them to X characters.
        #? The default is 20 characters.
        maxSubstitutionLength = 20;
        memoryLayout = {
          #> How to render the align information in a memory layout hover.
          alignment = "hexadecimal";
          #> Show memory layout data on hover.
          enable = true;
          #> How to render the niche information in a memory layout hover.
          niches = false;
          #> How to render the offset information in a memory layout hover.
          offset = "hexadecimal";
          #> How to render the padding information in a memory layout hover.
          padding = null;
          #> How to render the size information in a memory layout hover.
          size = "both";
        };
        show = {
          #> How many variants of an enum to display when hovering on. Show none if empty.
          enumVariants = 5;
          #> How many fields of a struct, variant or union to display when hovering on. Show none if empty.
          fields = 5;
          #> How many associated items of a trait to display when hovering a trait.
          traitAssocItems = null;
        };
      };

      imports = {
        granularity = {
          #> Enforce the import granularity setting for all files. If set to false rust-analyzer will try to keep import styles consistent per file.
          enforce = false;
          #> How imports should be grouped into use statements.
          #?  - crate: Merge imports from the same crate into a single use statement. Conversely, imports from different crates are split into separate statements.
          #?  - module: Merge imports from the same module into a single use statement. Conversely, imports from different modules are split into separate statements.
          #?  - item: Flatten imports so that each has its own use statement.
          #?  - one: Merge all imports into a single use statement as long as they have the same visibility and attributes.
          #?  - preserve: Deprecated - unless `enforceGranularity` is `true`, the style of the current file is preferred over this setting. Behaves like `item`.
          group = "crate";
        };
        group = {
          #> Group inserted imports by the [following order](https://rust-analyzer.github.io/book/features.html#auto-import). Groups are separated by newlines.
          enable = true;
        };
        merge = {
          #> Allow import insertion to merge new imports into single path glob imports like `use std::fmt::*;`.
          glob = true;
        };
        #> Prefer to unconditionally use imports of the core and alloc crate, over the std crate.
        preferNoStd = false;
        #> Prefer import paths containing a `prelude` module.
        preferPrelude = false;
        #> The path structure for newly inserted paths to use.
        #?  - plain: Insert import paths relative to the current module, using up to one `super` prefix if the parent module contains the requested item.
        #?  - self: Insert import paths relative to the current module, using up to one `super` prefix if the parent module contains the requested item. Prefixes `self` in front of the path if it starts with a module.
        #?  - crate: Force import paths to be absolute by always starting them with `crate` or the extern crate name they come from.
        prefix = "crate";
        #> Prefix external (including std, core) crate imports with `::`.
        #? E.g. `use ::std::io::Read;`.
        prefixExternPrelude = false;
      };

      inlayHints = {
        bindingModeHints = {
          #> Show inlay type hints for binding modes.
          enable = true;
        };
        chainingHints = {
          #> Show inlay type hints for method chains.
          enable = true;
        };
        closingBraceHints = {
          #> Show inlay hints after a closing `}` to indicate what item it belongs to.
          enable = true;
          #> Minimum number of lines required before the `}` until the hint is shown (set to 0 or 1 to always show them).
          minLines = 25;
        };
        closureCaptureHints = {
          #> Show inlay hints for closure and coroutine captures.
          enable = true;
        };
        closureReturnTypeHints = {
          #> Show inlay type hints for return types of closures.
          #?  - always: Always show type hints for return types of closures.
          #?  - never: Never show type hints for return types of closures.
          #?  - with_block: Only show type hints for return types of closures with blocks.
          enable = "always";
        };
        #> Closure notation in type and chaining inlay hints.
        #?  - impl_fn: `impl_fn`: `impl FnMut(i32, u64) -> i8`
        #?  - rust_analyzer: `rust_analyzer`: `|i32, u64| -> i8`
        #?  - with_id: `with_id`: `{closure#14352}`, where that id is the unique number of the closure in r-a internals
        #?  - hide: `hide`: Shows `...` for every closure type
        closureStyle = "impl_fn";
        discriminantHints = {
          #> Show enum variant discriminant hints.
          #?  - always: Always show all discriminant hints.
          #?  - never: Never show discriminant hints.
          #?  - fieldless: Only show discriminant hints on fieldless enum variants.
          enable = "never";
        };
        expressionAdjustmentHints = {
          #> Disable reborrows in expression adjustments inlay hints.
          #? Reborrows are a pair of a builtin deref then borrow, i.e. `&*`. They are inserted by the compiler but are mostly useless to the programmer.
          #? Note: if the deref is not builtin (an overloaded deref), or the borrow is `&raw const`/`&raw mut`, they are not removed.
          disableReborrows = true;
          #> Show inlay hints for type adjustments.
          #?  - always: Always show all adjustment hints.
          #?  - never: Never show adjustment hints.
          #?  - reborrow: Only show auto borrow and dereference adjustment hints.
          enable = "reborrow";
          #> Hide inlay hints for type adjustments outside of `unsafe` blocks.
          hideOutsideUnsafe = false;
          #> Show inlay hints as postfix ops (`.*` instead of `*`, etc).
          #?  - prefix: Always show adjustment hints as prefix (`*expr`).
          #?  - postfix: Always show adjustment hints as postfix (`expr.*`).
          #?  - prefer_prefix: Show prefix or postfix depending on which uses less parenthesis, preferring prefix.
          #?  - prefer_postfix: Show prefix or postfix depending on which uses less parenthesis, preferring postfix.
          mode = "prefix";
        };
        genericParameterHints = {
          const = {
            #> Show const generic parameter name inlay hints.
            enable = true;
          };
          lifetime = {
            #> Show generic lifetime parameter name inlay hints.
            enable = false;
          };
          type = {
            #> Show generic type parameter name inlay hints.
            enable = false;
          };
        };
        implicitDrops = {
          #> Show implicit drop hints.
          enable = false;
        };
        implicitSizedBoundHints = {
          #> Show inlay hints for the implied type parameter `Sized` bound.
          enable = false;
        };
        impliedDynTraitHints = {
          #> Show inlay hints for the implied `dyn` keyword in trait object types.
          enable = true;
        };
        lifetimeElisionHints = {
          #> Show inlay type hints for elided lifetimes in function signatures.
          #?  - always: Always show lifetime elision hints.
          #?  - never: Never show lifetime elision hints.
          #?  - skip_trivial: Only show lifetime elision hints if a return type is involved.
          enable = "skip_trivial";
          #> Prefer using parameter names as the name for elided lifetime hints if possible.
          useParameterNames = false;
        };
        #> Maximum length for inlay hints. Set to null to have an unlimited length.
        #? **Note:** This is mostly a hint, and we don't guarantee to strictly follow the limit.
        maxLength = 25;
        parameterHints = {
          #> Show function parameter name inlay hints at the call site.
          enable = true;
          missingArguments = {
            #> Show parameter name inlay hints for missing arguments at the call site.
            enable = false;
          };
        };
        rangeExclusiveHints = {
          #> Show exclusive range inlay hints.
          enable = false;
        };
        reborrowHints = {
          #> Show inlay hints for compiler inserted reborrows.
          #? This setting is deprecated in favor of #rust-analyzer.inlayHints.expressionAdjustmentHints.enable#.
          #?  - always: Always show reborrow hints.
          #?  - never: Never show reborrow hints.
          #?  - mutable: Only show mutable reborrow hints.
          enable = "never";
        };
        #> Whether to render leading colons for type hints, and trailing colons for parameter hints.
        renderColons = true;
        typeHints = {
          #> Show inlay type hints for variables.
          enable = true;
          #> Hide inlay type hints for `let` statements that initialize to a closure.
          #? Only applies to closures with blocks, same as `rust-analyzer.inlayHints.closureReturnTypeHints.enable`.
          hideClosureInitialization = false;
          #> Hide inlay parameter type hints for closures.
          hideClosureParameter = false;
          #> Hide inlay type hints for inferred types.
          hideInferredTypes = false;
          #> Hide inlay type hints for constructors.
          hideNamedConstructor = false;
          #> Where to render type hints relative to their binding pattern.
          #?  - inline: Render type hints directly after the binding identifier.
          #?  - end_of_line: Render type hints after the end of the containing `let` statement when possible.
          location = "inline";
        };
      };

      interpret = {
        #> Enable the experimental support for interpreting tests.
        tests = false;
      };

      joinLines = {
        #> Join lines merges consecutive declaration and initialization of an assignment.
        joinAssignments = true;
        #> Join lines inserts else between consecutive ifs.
        joinElseIf = true;
        #> Join lines removes trailing commas.
        removeTrailingComma = true;
        #> Join lines unwraps trivial blocks.
        unwrapTrivialBlock = true;
      };

      lens = {
        debug = {
          #> Show `Debug` lens. Only applies when `rust-analyzer.lens.enable` is set.
          enable = true;
        };
        #> Show CodeLens in Rust files.
        enable = true;
        implementations = {
          #> Show `Implementations` lens. Only applies when `rust-analyzer.lens.enable` is set.
          enable = true;
        };
        #> Where to render annotations.
        #?  - above_name: Render annotations above the name of the item.
        #?  - above_whole_item: Render annotations above the whole item, including documentation comments and attributes.
        location = "above_name";
        references = {
          adt = {
            #> Show `References` lens for Struct, Enum, and Union. Only applies when `rust-analyzer.lens.enable` is set.
            enable = false;
          };
          enumVariant = {
            #> Show `References` lens for Enum Variants. Only applies when `rust-analyzer.lens.enable` is set.
            enable = false;
          };
          method = {
            #> Show `Method References` lens. Only applies when `rust-analyzer.lens.enable` is set.
            enable = false;
          };
          trait = {
            #> Show `References` lens for Trait. Only applies when `rust-analyzer.lens.enable` is set.
            enable = false;
          };
        };
        run = {
          #> Show `Run` lens. Only applies when `rust-analyzer.lens.enable` is set.
          enable = true;
        };
        updateTest = {
          #> Show `Update Test` lens. Only applies when `rust-analyzer.lens.enable` and `rust-analyzer.lens.run.enable` are set.
          enable = true;
        };
      };

      lru = {
        #> Number of syntax trees rust-analyzer keeps in memory. Defaults to 128.
        capacity = null;
        query = {
          #> The LRU capacity of the specified queries.
          capacities = {};
        };
      };

      notifications = {
        #> Show `can't find Cargo.toml` error message.
        cargoTomlNotFound = true;
      };

      procMacro = {
        attributes = {
          #> Expand attribute macros. Requires `rust-analyzer.procMacro.enable` to be set.
          enable = true;
        };
        #> Enable support for procedural macros, implies `rust-analyzer.cargo.buildScripts.enable`.
        enable = true;
        #> These proc-macros will be ignored when trying to expand them.
        #? This config takes a map of crate names with the exported proc-macro names to ignore as values.
        ignored = {};
        #> Number of proc-macro server processes to spawn.
        #? Controls how many independent `proc-macro-srv` processes rust-analyzer runs in parallel to handle macro expansion.
        processes = 2;
        #> Internal config, path to proc-macro server executable.
        server = null;
      };

      profiling = {
        #> The path where to save memory profiling output.
        #? **Note:** Memory profiling is not enabled by default in rust-analyzer builds, you need to build from source for it.
        memoryProfile = null;
      };

      references = {
        #> Exclude imports from find-all-references.
        excludeImports = false;
        #> Exclude tests from find-all-references and call-hierarchy.
        excludeTests = false;
      };

      rename = {
        #> Whether to warn when a rename will cause conflicts (change the meaning of the code).
        showConflicts = true;
      };

      rustc = {
        #> Path to the Cargo.toml of the rust compiler workspace, for usage in rustc_private projects, or "discover" to try to automatically find it if the `rustc-dev` component is installed.
        #? Any project which uses rust-analyzer with the rustcPrivate crates must set `[package.metadata.rust-analyzer] rustc_private=true` to use it.
        #? This option does not take effect until rust-analyzer is restarted.
        source = null;
      };

      rustfmt = {
        #> Additional arguments to `rustfmt`.
        extraArgs = [];
        #> Advanced option, fully override the command rust-analyzer uses for formatting. This should be the equivalent of `rustfmt` here, and not that of `cargo fmt`. The file contents will be passed on the standard input and the formatted result will be read from the standard output.
        #? Note: The option must be specified as an array of command line arguments, with the first argument being the name of the command to run.
        overrideCommand = null;
        rangeFormatting = {
          #> Enables the use of rustfmt's unstable range formatting command for the `textDocument/rangeFormatting` request. The rustfmt option is unstable and only available on a nightly build.
          enable = false;
        };
      };

      semanticHighlighting = {
        comments = {
          #> Use semantic tokens for comments.
          #? In some editors (e.g. vscode) semantic tokens override other highlighting grammars. By disabling semantic tokens for comments, other grammars can be used to highlight their contents.
          enable = true;
        };
        doc = {
          comment = {
            inject = {
              #> Inject additional highlighting into doc comments.
              #? When enabled, rust-analyzer will highlight rust source in doc comments as well as intra doc links.
              enable = true;
            };
          };
        };
        #> Emit non-standard tokens and modifiers
        #? When enabled, rust-analyzer will emit tokens and modifiers that are not part of the standard set of semantic tokens.
        nonStandardTokens = true;
        operator = {
          #> Use semantic tokens for operators.
          #? When disabled, rust-analyzer will emit semantic tokens only for operator tokens when they are tagged with modifiers.
          enable = true;
          specialization = {
            #> Use specialized semantic tokens for operators.
            #? When enabled, rust-analyzer will emit special token types for operator tokens instead of the generic `operator` token type.
            enable = false;
          };
        };
        punctuation = {
          #> Use semantic tokens for punctuation.
          #? When disabled, rust-analyzer will emit semantic tokens only for punctuation tokens when they are tagged with modifiers or have a special role.
          enable = false;
          separate = {
            macro = {
              bang = {
                #> When enabled, rust-analyzer will emit a punctuation semantic token for the `!` of macro calls.
                enable = false;
              };
            };
          };
          specialization = {
            #> Use specialized semantic tokens for punctuation.
            #? When enabled, rust-analyzer will emit special token types for punctuation tokens instead of the generic `punctuation` token type.
            enable = false;
          };
        };
        strings = {
          #> Use semantic tokens for strings.
          #? In some editors (e.g. vscode) semantic tokens override other highlighting grammars. By disabling semantic tokens for strings, other grammars can be used to highlight their contents.
          enable = true;
        };
      };

      signatureInfo = {
        #> Show full signature of the callable. Only shows parameters if disabled.
        #?  - full: Show the entire signature.
        #?  - parameters: Show only the parameters.
        detail = "full";
        documentation = {
          #> Show documentation.
          enable = true;
        };
      };

      vfs = {
        #> Additional paths to include in the VFS. Generally for code that is generated or otherwise managed by a build system outside of Cargo, though Cargo might be the eventual consumer.
        extraIncludes = [];
      };

      workspace = {
        #> Configure a command that rust-analyzer can invoke to obtain configuration.
        #? This is an alternative to manually generating `rust-project.json`: it enables rust-analyzer to generate rust-project.json on the fly, and regenerate it when switching or modifying projects.
        #? This is an object with three fields:
        #? * `command`: the shell command to invoke
        #? * `filesToWatch`: which build system-specific files should be watched to trigger regenerating the configuration
        #? * `progressLabel`: the name of the command, used in progress indicators in the IDE
        #? Here's an example of a valid configuration:
        #? ```json
        #? "rust-analyzer.workspace.discoverConfig": {
        #?         "command": [
        #?                 "rust-project",
        #?                 "develop-json",
        #?                 "{arg}"
        #?         ],
        #?         "progressLabel": "buck2/rust-project",
        #?         "filesToWatch": [
        #?                 "BUCK"
        #?         ]
        #? }
        #? ```
        #? ## Argument Substitutions
        #? If `command` includes the argument `{arg}`, that argument will be substituted with the JSON-serialized form of the following enum:
        #? ```norun
        #? #[derive(PartialEq, Clone, Debug, Serialize)]
        #? #[serde(rename_all = "camelCase")]
        #? pub enum DiscoverArgument {
        #?      Path(AbsPathBuf),
        #?      Buildfile(AbsPathBuf),
        #? }
        #? ```
        #? rust-analyzer will use the path invocation to find and generate a `rust-project.json` and therefore a workspace. Example:
        #? ```norun
        #? rust-project develop-json '{ "path": "myproject/src/main.rs" }'
        #? ```
        #? rust-analyzer will use build file invocations to update an existing workspace. Example:
        #? Or with a build file and the configuration above:
        #? ```norun
        #? rust-project develop-json '{ "buildfile": "myproject/BUCK" }'
        #? ```
        #? As a reference for implementors, buck2's `rust-project` will likely be useful: <https://github.com/facebook/buck2/tree/main/integrations/rust-project>.
        #? ## Discover Command Output
        #? **Warning**: This format is provisional and subject to change.
        #? The discover command should output JSON objects to stdout, one per line (JSONL format). These objects should correspond to this Rust data type:
        #? ```norun
        #? #[derive(Debug, Clone, Deserialize, Serialize)]
        #? #[serde(tag = "kind")]
        #? #[serde(rename_all = "snake_case")]
        #? enum DiscoverProjectData {
        #?         Finished { buildfile: Utf8PathBuf, project: ProjectJsonData },
        #?         Error { error: String, source: Option<String> },
        #?         Progress { message: String },
        #? }
        #? ```
        #? For example, a progress event:
        #? ```json
        #? {"kind":"progress","message":"generating rust-project.json"}
        #? ```
        #? A finished event can look like this (expanded and commented for readability):
        #? ```json
        #? {
        #?         // the internally-tagged representation of the enum.
        #?         "kind": "finished",
        #?         // the file used by a non-Cargo build system to define
        #?         // a package or target.
        #?         "buildfile": "rust-analyzer/BUCK",
        #?         // the contents of a rust-project.json, elided for brevity
        #?         "project": {
        #?                 "sysroot": "foo",
        #?                 "crates": []
        #?         }
        #? }
        #? ```
        #? Only the finished event is required, but the other variants are encouraged to give users more feedback about progress or errors.
        #? Stderr is not parsed as JSONL. It is treated as command log output and forwarded to rust-analyzer's own logs.
        discoverConfig = null;

        symbol = {
          search = {
            #> Exclude all imports from workspace symbol search.
            #? In addition to regular imports (which are always excluded), this option removes public imports (better known as re-exports) and removes imports that rename the imported symbol.
            excludeImports = false;
            #> Workspace symbol search kind.
            #?  - only_types: Search for types only.
            #?  - all_symbols: Search for all symbols kinds.
            kind = "only_types";
            #> Limits the number of items returned from a workspace symbol search (Defaults to 128).
            #? Some clients like vs-code issue new searches on result filtering and don't require all results to be returned in the initial search.
            #? Other clients requires all results upfront and might require a higher limit.
            limit = 128;
            #> Workspace symbol search scope.
            #?  - workspace: Search in current workspace only.
            #?  - workspace_and_dependencies: Search in current workspace and dependencies.
            scope = "workspace";
          };
        };
      };
    };
  };
in {inherit enable extensions options settings;}
