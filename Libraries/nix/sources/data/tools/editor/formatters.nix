{
  mkAliasFamily,
  mkSource,
  ...
}: {
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

  deno = mkSource {
    categories = ["formatters" "scripting"];
    description = "TypeScript and JavaScript runtime with built-in tooling";
    aliases = mkAliasFamily "deno" {
      Add = {
        args = ["add"];
        description = "add dependencies, e.g. denoAdd jsr:@std/path";
      };
      ApproveScripts = {
        args = ["approve-scripts"];
        description = "approve npm lifecycle scripts";
      };
      Audit = {
        args = ["audit"];
        description = "audit currently installed dependencies";
      };
      Bench = {
        args = ["bench"];
        description = "run benchmarks";
      };
      BumpVersion = {
        args = ["bump-version"];
        description = "update the version in the configuration file";
      };
      Bundle = {
        args = ["bundle"];
        description = "output a single JavaScript file with all dependencies";
      };
      Cache = {
        args = ["cache"];
        description = "cache the dependencies";
      };
      Check = {
        args = ["check"];
        description = "type-check the dependencies without running them";
      };
      Ci = {
        args = ["ci"];
        description = "install dependencies from a lockfile in a frozen state";
      };
      Clean = {
        args = ["clean"];
        description = "remove the deno cache directory";
      };
      Compile = {
        args = ["compile"];
        description = "compile a script into a self-contained executable";
      };
      Completions = {
        args = ["completions"];
        description = "generate shell completions, e.g. denoCompletions fish";
      };
      Coverage = {
        args = ["coverage"];
        description = "print a coverage report";
      };
      Create = {
        args = ["create"];
        description = "create a project from a template";
      };
      Deploy = {
        args = ["deploy"];
        description = "deploy to Deno Deploy";
      };
      Desktop = {
        args = ["desktop"];
        description = "compile a script into a desktop application";
      };
      Doc = {
        args = ["doc"];
        description = "generate and show documentation for a module or built-ins";
      };
      Eval = {
        args = ["eval"];
        description = "evaluate a script string, e.g. denoEval 'console.log(1 + 1)'";
      };
      Fmt = {
        args = ["fmt"];
        description = "format source files in place";
      };
      FmtCheck = {
        args = ["fmt" "--check"];
        description = "check formatting without changing files";
      };
      Info = {
        args = ["info"];
        description = "show info about the cache or about a source file";
      };
      Init = {
        args = ["init"];
        description = "initialize a new project";
      };
      Install = {
        args = ["install"];
        description = "install dependencies locally, or a script globally to the bin directory";
      };
      Jupyter = {
        args = ["jupyter"];
        description = "run the deno kernel for Jupyter notebooks";
      };
      Link = {
        args = ["link"];
        description = "link a local JSR package into the current project for development";
      };
      Lint = {
        args = ["lint"];
        description = "lint source files without changing them";
      };
      LintFix = {
        args = ["lint" "--fix"];
        description = "lint source files and apply automatic fixes";
      };
      List = {
        args = ["list"];
        description = "list the dependencies declared in deno.json or package.json";
      };
      Lsp = {
        args = ["lsp"];
        description = "start the language server";
      };
      Outdated = {
        args = ["outdated"];
        description = "find outdated dependencies";
      };
      Pack = {
        args = ["pack"];
        description = "create a tarball of the package";
      };
      Publish = {
        args = ["publish"];
        description = "publish the current package or workspace";
      };
      PublishDry = {
        args = ["publish" "--dry-run"];
        description = "check what publishing would do without publishing";
      };
      Remove = {
        args = ["remove"];
        description = "remove dependencies";
      };
      Repl = {
        args = ["repl"];
        description = "start an interactive REPL";
      };
      Run = {
        args = ["run"];
        description = "run a JavaScript or TypeScript program, or a task, e.g. denoRun main.ts";
      };
      RunAll = {
        args = ["run" "--allow-all"];
        description = "run a program with every permission granted";
      };
      Sandbox = {
        args = ["sandbox"];
        description = "run in sandbox mode";
      };
      Serve = {
        args = ["serve"];
        description = "run a server";
      };
      Task = {
        args = ["task"];
        description = "run a task from the configuration file, or list tasks when given none";
      };
      Test = {
        args = ["test"];
        description = "run tests";
      };
      TestCoverage = {
        args = ["test" "--coverage"];
        description = "run tests and collect coverage data";
      };
      TestWatch = {
        args = ["test" "--watch"];
        description = "run tests again whenever files change";
      };
      Transpile = {
        args = ["transpile"];
        description = "transpile TypeScript, JSX or TSX files to JavaScript";
      };
      Types = {
        args = ["types"];
        description = "print runtime TypeScript declarations";
      };
      Uninstall = {
        args = ["uninstall"];
        description = "uninstall a dependency or an executable script";
      };
      Unlink = {
        args = ["unlink"];
        description = "remove a linked local package from the current project";
      };
      Update = {
        args = ["update"];
        description = "update outdated dependencies";
      };
      Upgrade = {
        args = ["upgrade"];
        description = "upgrade the deno executable to a given version";
      };
      Watch = {
        args = ["watch"];
        description = "run a program and hot-replace modules when files change";
      };
      Why = {
        args = ["why"];
        description = "show why a package is installed";
      };
      X = {
        args = ["x"];
        description = "execute a binary from npm or jsr, like npx";
      };
    };
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

  treefmt = mkSource {
    categories = ["formatters" "scripting"];
    description = "multi-language code formatter";
    input = "treefmt";
    target = "treefmt";
    exe = "treefmt";
  };
}
