/**
Test collector.

Takes the shared args (`{lix, host, context, api}`) positionally, builds the
harness, discovers every suite under this directory and returns one report.

  nix-repl> :p tests.summary
  nix-repl> :p tests.bySuite
  nix-repl> :p tests.failures
  nix-repl> :p tests.lines
  nix-repl> :p tests.skipped

The tree mirrors the source: the test for `libraries/types/host/kernel.nix` is
`tests/libraries/types/host/kernel.nix`, and a directory's `default.nix` tests
that directory's own `default.nix`.

A suite is a file that is a function `args: harness: [cases]`. Any other `.nix`
file, such as a fixture sitting beside the tests that use it, is not run and
is listed in `tests.skipped` so it is never silently lost. This file and
`harness.nix` are ignored at the top level.
*/
args: let
  harness = import ./harness.nix args.lix;
  ignoredAtTop = ["default.nix" "harness.nix"];

  discover = directory: relative: let
    entries = builtins.readDir directory;
    names =
      builtins.filter
      (name: !(relative == "" && builtins.elem name ignoredAtTop))
      (builtins.attrNames entries);

    visit = found: name: let
      path = directory + "/${name}";
      key =
        if relative == ""
        then name
        else "${relative}/${name}";
      stem = builtins.match "(.*)\\.nix" key;
      inner = discover path key;
    in
      if entries.${name} == "directory"
      then {
        suites = found.suites // inner.suites;
        skipped = found.skipped ++ inner.skipped;
      }
      else if stem == null
      then found
      else if builtins.isFunction (import path)
      then
        found
        // {
          suites = found.suites // {${builtins.head stem} = import path args harness;};
        }
      else found // {skipped = found.skipped ++ [key];};
  in
    builtins.foldl' visit {
      suites = {};
      skipped = [];
    }
    names;

  found = discover ./. "";
in
  harness.report found.suites // {inherit (found) skipped;}
