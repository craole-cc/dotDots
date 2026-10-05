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
is listed in `tests.skipped` so it is never silently lost. This file,
`harness.nix` and `fixtures/` are ignored at the top level; fixtures reach the
suites as `harness.fixtures`.
*/
args: let
  inherit (args) lix;

  inherit (lix.attrsets) attrNames;
  inherit (lix.lists) elem filter foldl' head;
  inherit (lix.filesystem) readDir;
  inherit (lix.strings) match;
  inherit (lix.trivial) isFunction;

  fixtures = import ./fixtures;
  harness = import ./harness.nix {inherit lix fixtures;};
  ignoredAtTop = ["default.nix" "harness.nix" "fixtures"];

  discover = directory: relative: let
    entries = readDir directory;
    names =
      filter
      (name: !(relative == "" && elem name ignoredAtTop))
      (attrNames entries);

    visit = found: name: let
      path = directory + "/${name}";
      key =
        if relative == ""
        then name
        else "${relative}/${name}";
      stem = match "(.*)\\.nix" key;
      inner = discover path key;
    in
      if entries.${name} == "directory"
      then {
        suites = found.suites // inner.suites;
        skipped = found.skipped ++ inner.skipped;
      }
      else if stem == null
      then found
      else if isFunction (import path)
      then
        found
        // {
          suites = found.suites // {${head stem} = import path args harness;};
        }
      else found // {skipped = found.skipped ++ [key];};
  in
    foldl' visit {
      suites = {};
      skipped = [];
    }
    names;

  found = discover ./. "";
in
  harness.report found.suites // {inherit (found) skipped;}
